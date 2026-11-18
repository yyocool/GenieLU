using System.Collections.Concurrent;
using SkiaSharp;

namespace LabelUp.Editor.Services;

/// <summary>데이터 열의 이미지 URL을 필요할 때 받아 캐시한다.</summary>
public static class BoundImageCache
{
    private static readonly ConcurrentDictionary<string, SKBitmap?> Bitmaps = new(StringComparer.OrdinalIgnoreCase);
    private static readonly ConcurrentDictionary<string, byte> Pending = new(StringComparer.OrdinalIgnoreCase);
    private static Func<string, Task<string?>>? _fetch;
    private static Action? _onReady;

    public static void Configure(Func<string, Task<string?>> fetch, Action onReady)
    {
        _fetch = fetch;
        _onReady = onReady;
    }

    public static SKBitmap? Get(string? src)
    {
        if (string.IsNullOrWhiteSpace(src)) return null;
        if (Bitmaps.TryGetValue(src, out var bmp)) return bmp;
        Request(src);
        return null;
    }

    public static bool IsLoaded(string? src)
        => !string.IsNullOrWhiteSpace(src) && Bitmaps.TryGetValue(src, out var bmp) && bmp != null;

    /// <summary>이미 화소를 가진 그림을 URL 로 올렸을 때, 다시 받지 않도록 미리 넣어 둔다.</summary>
    public static void Put(string src, SKBitmap bitmap)
    {
        if (string.IsNullOrWhiteSpace(src)) return;
        Bitmaps[src] = bitmap;
    }

    /// <summary>
    /// 인쇄·내보내기처럼 한 번에 그려 끝내는 곳이 쓴다. 받는 중인 그림을 기다리지 않으면
    /// 그 그림이 빠진 채 인쇄된다. 실패한 그림은 기다리지 않는다.
    /// </summary>
    public static async Task WaitForAsync(IEnumerable<string?> sources, int timeoutMs = 15000)
    {
        var urls = sources
            .Where(s => !string.IsNullOrWhiteSpace(s) && LooksLikeUrl(s)
                        && !s!.StartsWith("data:", StringComparison.OrdinalIgnoreCase))
            .Select(s => s!)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
        if (urls.Count == 0) return;
        foreach (var url in urls)
            Request(url);
        var deadline = DateTime.UtcNow.AddMilliseconds(timeoutMs);
        while (urls.Any(u => !Bitmaps.ContainsKey(u)) && DateTime.UtcNow < deadline)
            await Task.Delay(100);
    }

    public static void Request(string? src)
    {
        if (string.IsNullOrWhiteSpace(src) || !LooksLikeUrl(src)) return;
        if (Bitmaps.ContainsKey(src) || !Pending.TryAdd(src, 1)) return;
        var fetch = _fetch;
        if (fetch is null) return;
        _ = LoadAsync(src, fetch);
    }

    private static async Task LoadAsync(string src, Func<string, Task<string?>> fetch)
    {
        try
        {
            var dataUrl = await fetch(src);
            if (string.IsNullOrWhiteSpace(dataUrl))
            {
                // 재요청 폭주 방지 (실패도 캐시)
                Bitmaps[src] = null;
                return;
            }

            // fetch 쪽에서 SVG→PNG 래스터화를 기대. 혹시 svg+xml이 오면 디코드 불가.
            if (dataUrl.StartsWith("data:image/svg", StringComparison.OrdinalIgnoreCase))
            {
                EditorLog.Warn($"SVG 래스터화 누락: {src}");
                Bitmaps[src] = null;
                return;
            }

            var comma = dataUrl.IndexOf(',');
            var meta = comma >= 0 ? dataUrl[..comma] : "";
            var raw = comma >= 0 ? dataUrl[(comma + 1)..] : dataUrl;
            if (meta.Length > 0 && meta.IndexOf("base64", StringComparison.OrdinalIgnoreCase) < 0)
            {
                EditorLog.Warn($"base64 아닌 data URL: {src}");
                Bitmaps[src] = null;
                return;
            }

            var bytes = Convert.FromBase64String(raw);
            if (LooksLikeSvgBytes(bytes))
            {
                EditorLog.Warn($"SVG 바이트는 Skia 디코드 불가: {src}");
                Bitmaps[src] = null;
                return;
            }

            using var data = SKData.CreateCopy(bytes);
            var bmp = SKBitmap.Decode(data);
            if (bmp is null)
            {
                EditorLog.Warn($"이미지 디코드 실패: {src}");
                Bitmaps[src] = null;
                return;
            }

            Bitmaps[src] = bmp;
            _onReady?.Invoke();
        }
        catch (Exception ex)
        {
            EditorLog.Warn($"데이터 이미지 로드 실패: {src} · {ex.Message}");
            Bitmaps[src] = null;
        }
        finally
        {
            Pending.TryRemove(src, out _);
        }
    }

    private static bool LooksLikeSvgBytes(byte[] bytes)
    {
        if (bytes is not { Length: >= 4 }) return false;
        // UTF-8 BOM / whitespace / '<'
        var i = 0;
        if (bytes.Length >= 3 && bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) i = 3;
        while (i < bytes.Length && bytes[i] is (byte)'\r' or (byte)'\n' or (byte)' ' or (byte)'\t') i++;
        if (i >= bytes.Length || bytes[i] != (byte)'<') return false;
        var n = Math.Min(bytes.Length - i, 256);
        var head = System.Text.Encoding.UTF8.GetString(bytes, i, n);
        return head.Contains("<svg", StringComparison.OrdinalIgnoreCase)
               || head.StartsWith("<?xml", StringComparison.OrdinalIgnoreCase);
    }

    public static bool LooksLikeUrl(string? src)
    {
        if (string.IsNullOrWhiteSpace(src) || src.Length < 2) return false;
        if (src.StartsWith("http://", StringComparison.OrdinalIgnoreCase)
            || src.StartsWith("https://", StringComparison.OrdinalIgnoreCase)
            || src.StartsWith("data:image", StringComparison.OrdinalIgnoreCase)
            || src.StartsWith("//"))
            return true;
        if (src.StartsWith("/assets/", StringComparison.OrdinalIgnoreCase)
            || src.StartsWith("assets/", StringComparison.OrdinalIgnoreCase))
            return true;
        return false;
    }
}
