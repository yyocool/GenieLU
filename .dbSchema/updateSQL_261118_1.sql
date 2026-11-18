-- updateSQL_261118_1.sql
-- 라벨 규격 치수를 표기치수로 맞춘다. 스키마 변경 없음(데이터만).
--   id 61  199.9x289.05mm 투명 1칸 (LC101, PC101) -> 200x289mm
--   id 26  45.7x21.2mm 백색 48칸 (A412)          -> 46x21mm
-- 편집기 인쇄는 이 값으로 칸 위치를 계산하므로, 칸 중심이 실제 용지와 같은 자리에 오도록
-- 크기가 줄거나 는 만큼 간격·여백을 반대로 보정한다.
--   A412: 가로 피치 45.7+2.54 = 46+2.24 = 48.24, 세로 피치 21.2+0 = 21+0.2 = 21.2
--         왼쪽 여백 9.75-0.15 = 9.60, 위쪽 여백 21.41+0.10 = 21.51
--   LC101: 왼쪽 여백 5.40-0.05 = 5.35, 위쪽 여백 4.699+0.025 = 4.724

UPDATE label_specs
SET name = '200x289mm 투명 1칸',
    width_mm = 200.00,
    height_mm = 289.00,
    left_margin_mm = 5.350,
    top_margin_mm = 4.724,
    updated_at = NOW()
WHERE id = 61 AND width_mm = 199.90 AND height_mm = 289.05;

UPDATE label_specs
SET name = '46x21mm 백색 48칸',
    width_mm = 46.00,
    height_mm = 21.00,
    h_gap_mm = 2.240,
    v_gap_mm = 0.200,
    left_margin_mm = 9.600,
    top_margin_mm = 21.510,
    updated_at = NOW()
WHERE id = 26 AND width_mm = 45.70 AND height_mm = 21.20;
