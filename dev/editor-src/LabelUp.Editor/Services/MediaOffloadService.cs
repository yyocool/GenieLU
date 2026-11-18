using System.Runtime.CompilerServices;
using System.Security.Cryptography;
using System.Text.Json;
using LabelUp.Editor.Models;
using Microsoft.JSInterop;

namespace LabelUp.Editor.Services;

/// <summary>
/// 문서에 data URL 로 들어간 큰 그림을 서버(/assets/editor-media)에 올리고 주소로 바꾼다.
/// 그림이 칸마다 복사돼도 문서·실행 취소 기록·저장 요청에는 주소만 남아,
/// 브라우저 메모리가 바닥나 저장이 실패하는 일을 막는다.
/// 로그인하지 않았거나 올리지 못하면 data URL 을 그대로 둔다.
/// </summary>
public sealed class MediaOffloadService(IJSRuntime js, EditorSession session)
{
    // 서버 EditorWorkspaceService::storeMediaDataUrl 과 같은 기준. 이보다 작은 아이콘은 문서에 둔다.
    private const int MinLength = 24_000;
    private static readonly TimeSpan GuestBackoff = TimeSpan.FromMinutes(1);

    private readonly SemaphoreSlim _gate = new(1, 1);
    private readonly ConditionalWeakTable<string, string> _urlByInstance = new();
    private readonly ConditionalWeakTable<string, string> _failed = new();
    private readonly Dictionary<string, string> _urlByHash = new(StringComparer.Ordinal);
    private DateTime _guestUntil = DateTime.MinValue;
    private bool _queued;
    private bool _attached;

    public void Attach()
    {
        if (_attached) return;
        _attached = true;
        session.Changed += OnChanged;
    }

    /// <summary>저장 직전에 부른다. 남은 data URL 그림을 모두 올린 뒤 돌아온다.</summary>
    public async Task FlushAsync()
    {
        try
        {
            await OffloadAsync(force: true);
        }
        catch (Exception ex)
        {
            EditorLog.Warn("저장 전 그림 올리기 실패: " + ex.Message);
        }
    }

    private void OnChanged()
    {
        if (_queued || DateTime.UtcNow < _guestUntil || !HasPending()) return;
        _queued = true;
        _ = RunQueuedAsync();
    }

    private async Task RunQueuedAsync()
    {
        try
        {
            // 그림을 넣자마자 이어지는 전체 적용·이동을 한 번에 받아 올리려고 잠깐 기다린다.
            await Task.Delay(300);
            _queued = false;
            await OffloadAsync(force: false);
        }
        catch (Exception ex)
        {
            _queued = false;
            EditorLog.Warn("그림 올리기 실패: " + ex.Message);
        }
    }

    private bool HasPending()
    {
        foreach (var o in Objects(session.Document))
        {
            if (IsCandidate(o.ImageData) && !_failed.TryGetValue(o.ImageData!, out _))
                return true;
        }
        return false;
    }

    private async Task OffloadAsync(bool force)
    {
        if (!force && DateTime.UtcNow < _guestUntil) return;
        await _gate.WaitAsync();
        try
        {
            var replaced = 0;
            var stop = false;
            // 올리는 사이 전체 적용·실행 취소로 새 그림 인스턴스가 생길 수 있어, 바퀴마다 문서를 다시 훑는다.
            for (var round = 0; round < 4 && !stop; round++)
            {
                var pending = new List<string>();
                var seen = new HashSet<object>(ReferenceEqualityComparer.Instance);
                foreach (var o in Objects(session.Document))
                {
                    var s = o.ImageData;
                    if (!IsCandidate(s) || _failed.TryGetValue(s!, out _) || _urlByInstance.TryGetValue(s!, out _))
                        continue;
                    if (seen.Add(s!))
                        pending.Add(s!);
                }

                foreach (var data in pending)
                {
                    var (url, guest) = await UploadAsync(data);
                    if (guest)
                    {
                        _guestUntil = DateTime.UtcNow + GuestBackoff;
                        stop = true;
                        break;
                    }
                    if (url is null)
                        _failed.AddOrUpdate(data, "");
                    else
                        _urlByInstance.AddOrUpdate(data, url);
                }

                var changed = 0;
                foreach (var o in Objects(session.Document))
                {
                    if (o.ImageData is { } s && _urlByInstance.TryGetValue(s, out var url))
                    {
                        o.ImageData = url;
                        changed++;
                    }
                }
                replaced += changed;
                if (pending.Count == 0 && changed == 0)
                    break;
            }

            if (replaced > 0)
            {
                EditorLog.Info($"그림 {replaced}곳을 서버 주소로 바꿨습니다");
                session.Notify();
            }
        }
        finally
        {
            _gate.Release();
        }
    }

    private async Task<(string? Url, bool Guest)> UploadAsync(string dataUrl)
    {
        var bytes = RasterImage.TryReadDataUrl(dataUrl);
        if (bytes is not { Length: > 32 })
            return (null, false);

        var hash = HashOf(bytes);
        if (hash is not null && _urlByHash.TryGetValue(hash, out var known))
            return (known, false);

        var raw = await js.InvokeAsync<JsonElement>("labelUpEditor.uploadEditorMedia", bytes, MimeOf(dataUrl));
        var status = raw.TryGetProperty("status", out var st) && st.TryGetInt32(out var code) ? code : 0;
        var url = raw.TryGetProperty("url", out var u) ? u.GetString() ?? "" : "";
        if (status == 401)
            return (null, true);
        if (status != 200 || !url.StartsWith("/assets/", StringComparison.Ordinal))
        {
            var message = raw.TryGetProperty("message", out var m) ? m.GetString() : "";
            EditorLog.Warn($"그림 올리기 실패 ({status}): {message}");
            return (null, false);
        }

        if (hash is not null)
            _urlByHash[hash] = url;
        if (!BoundImageCache.IsLoaded(url) && RasterImage.Decode(bytes) is { } bmp)
            BoundImageCache.Put(url, bmp);
        return (url, false);
    }

    private static string MimeOf(string dataUrl)
    {
        var comma = dataUrl.IndexOf(',');
        var head = comma > 5 ? dataUrl[5..comma] : "";
        var semi = head.IndexOf(';');
        return semi >= 0 ? head[..semi] : head;
    }

    private static string? HashOf(byte[] bytes)
    {
        try
        {
            return Convert.ToHexString(SHA1.HashData(bytes));
        }
        catch (Exception ex)
        {
            // 같은 그림을 다시 올려도 서버가 sha1 로 한 파일에 모은다.
            EditorLog.Info("그림 해시 생략: " + ex.Message);
            return null;
        }
    }

    private static bool IsCandidate(string? s)
        => s is { Length: >= MinLength } && s.StartsWith("data:image/", StringComparison.OrdinalIgnoreCase);

    private static IEnumerable<DesignObject> Objects(LabelDocument doc)
    {
        foreach (var page in doc.Pages)
        foreach (var cell in page.Cells)
        foreach (var o in cell.Objects)
            yield return o;
    }
}
