-- updateSQL_261119_1.sql
-- 상품 상세 표기치수에 맞춰 라벨 규격 치수를 맞춘다. 스키마 변경 없음(데이터만).
-- 편집기 인쇄는 이 값으로 칸 위치를 계산하므로, 칸 중심이 실제 용지와 같은 자리에 오도록
-- 크기가 줄거나 는 만큼 간격·여백을 반대로 보정한다. 간격이 0 아래로 내려가면 0으로 두고 여백만 보정한다.
--
--   LT102/IC102/LC102/AK102  199.9x143.51 -> 200x143.5   (2칸)
--   LT204                    99.06x67.71  -> 99.1x67.7   (8칸)
--   LT208                    99.06x33.85  -> 99.1x33.9   (16칸)
--   LT307/IC307/LC307/AK307  63.5x38.1    -> 63.5x38     (21칸)
--   LN101R/G/Y, AP101Y/G/P/B, AK101
--                            199.9x289.05 -> 200x289     (1칸)
--   AK207                    99.06x38.1   -> 99.1x38     (14칸)

-- 2칸 199.9x143.51 -> 200x143.5
--   dw +0.10, dh -0.01 / 1열 2행: v_gap 0->0.01, left 5.410-0.05, top 5.715+0.005
UPDATE label_specs s
INNER JOIN shop_products p ON p.spec_id = s.id
SET s.name = REPLACE(s.name, '199.9x143.51mm', '200x143.5mm'),
    s.width_mm = 200.00,
    s.height_mm = 143.50,
    s.v_gap_mm = 0.010,
    s.left_margin_mm = 5.360,
    s.top_margin_mm = 5.720,
    s.updated_at = NOW()
WHERE p.sku IN ('LT102', 'IC102', 'LC102', 'AK102')
  AND s.width_mm = 199.90
  AND s.height_mm = 143.51;

-- 8칸 99.06x67.71 -> 99.1x67.7
--   dw +0.04, dh -0.01 / 2열 4행: h_gap 2.540-0.04, v_gap 0->0.01, left 5.086-0.02, top 13.792+0.005
UPDATE label_specs s
INNER JOIN shop_products p ON p.spec_id = s.id
SET s.name = REPLACE(s.name, '99.06x67.71mm', '99.1x67.7mm'),
    s.width_mm = 99.10,
    s.height_mm = 67.70,
    s.h_gap_mm = 2.500,
    s.v_gap_mm = 0.010,
    s.left_margin_mm = 5.066,
    s.top_margin_mm = 13.797,
    s.updated_at = NOW()
WHERE p.sku = 'LT204'
  AND s.width_mm = 99.06
  AND s.height_mm = 67.71;

-- 16칸 99.06x33.85 -> 99.1x33.9
--   dw +0.04, dh +0.05 / 2열 8행: h_gap 2.540-0.04, v_gap은 0 유지, left 5.086-0.02, top 13.792-0.025
UPDATE label_specs s
INNER JOIN shop_products p ON p.spec_id = s.id
SET s.name = REPLACE(s.name, '99.06x33.85mm', '99.1x33.9mm'),
    s.width_mm = 99.10,
    s.height_mm = 33.90,
    s.h_gap_mm = 2.500,
    s.left_margin_mm = 5.066,
    s.top_margin_mm = 13.767,
    s.updated_at = NOW()
WHERE p.sku = 'LT208'
  AND s.width_mm = 99.06
  AND s.height_mm = 33.85;

-- 21칸 63.5x38.1 -> 63.5x38
--   dw 0, dh -0.10 / 3열 7행: v_gap 0->0.10, top 15.875+0.05
UPDATE label_specs s
INNER JOIN shop_products p ON p.spec_id = s.id
SET s.name = REPLACE(s.name, '63.5x38.1mm', '63.5x38mm'),
    s.width_mm = 63.50,
    s.height_mm = 38.00,
    s.v_gap_mm = 0.100,
    s.top_margin_mm = 15.925,
    s.updated_at = NOW()
WHERE p.sku IN ('LT307', 'IC307', 'LC307', 'AK307')
  AND s.width_mm = 63.50
  AND s.height_mm = 38.10;

-- 1칸 199.9x289.05 -> 200x289
--   dw +0.10, dh -0.05: left 5.400-0.05, top 4.699+0.025 (LC101과 동일 보정)
UPDATE label_specs s
INNER JOIN shop_products p ON p.spec_id = s.id
SET s.name = REPLACE(s.name, '199.9x289.05mm', '200x289mm'),
    s.width_mm = 200.00,
    s.height_mm = 289.00,
    s.left_margin_mm = 5.350,
    s.top_margin_mm = 4.724,
    s.updated_at = NOW()
WHERE p.sku IN ('LN101R', 'LN101G', 'LN101Y', 'AP101Y', 'AP101G', 'AP101P', 'AP101B', 'AK101')
  AND s.width_mm = 199.90
  AND s.height_mm = 289.05;

-- 14칸 99.06x38.1 -> 99.1x38
--   dw +0.04, dh -0.10 / 2열 7행: h_gap 2.540-0.04, v_gap 0->0.10, left 5.086-0.02, top 15.875+0.05
UPDATE label_specs s
INNER JOIN shop_products p ON p.spec_id = s.id
SET s.name = REPLACE(s.name, '99.06x38.1mm', '99.1x38mm'),
    s.width_mm = 99.10,
    s.height_mm = 38.00,
    s.h_gap_mm = 2.500,
    s.v_gap_mm = 0.100,
    s.left_margin_mm = 5.066,
    s.top_margin_mm = 15.925,
    s.updated_at = NOW()
WHERE p.sku = 'AK207'
  AND s.width_mm = 99.06
  AND s.height_mm = 38.10;
