-- updateSQL_261119_2.sql
-- 편집기(label_specs 치수·여백)는 원본으로 되돌리고,
-- 상품 상세 표기치수만 shop_products.display_width_mm / display_height_mm 에 둔다.

-- 2칸 200x143.5 -> 199.9x143.51
UPDATE label_specs s
INNER JOIN shop_products p ON p.spec_id = s.id
SET s.name = REPLACE(s.name, '200x143.5mm', '199.9x143.51mm'),
    s.width_mm = 199.90,
    s.height_mm = 143.51,
    s.v_gap_mm = 0.000,
    s.left_margin_mm = 5.410,
    s.top_margin_mm = 5.715,
    s.updated_at = NOW()
WHERE p.sku IN ('LT102', 'IC102', 'LC102', 'AK102')
  AND s.width_mm = 200.00
  AND s.height_mm = 143.50;

-- 8칸 99.1x67.7 -> 99.06x67.71
UPDATE label_specs s
INNER JOIN shop_products p ON p.spec_id = s.id
SET s.name = REPLACE(s.name, '99.1x67.7mm', '99.06x67.71mm'),
    s.width_mm = 99.06,
    s.height_mm = 67.71,
    s.h_gap_mm = 2.540,
    s.v_gap_mm = 0.000,
    s.left_margin_mm = 5.086,
    s.top_margin_mm = 13.792,
    s.updated_at = NOW()
WHERE p.sku = 'LT204'
  AND s.width_mm = 99.10
  AND s.height_mm = 67.70;

-- 16칸 99.1x33.9 -> 99.06x33.85
UPDATE label_specs s
INNER JOIN shop_products p ON p.spec_id = s.id
SET s.name = REPLACE(s.name, '99.1x33.9mm', '99.06x33.85mm'),
    s.width_mm = 99.06,
    s.height_mm = 33.85,
    s.h_gap_mm = 2.540,
    s.left_margin_mm = 5.086,
    s.top_margin_mm = 13.792,
    s.updated_at = NOW()
WHERE p.sku = 'LT208'
  AND s.width_mm = 99.10
  AND s.height_mm = 33.90;

-- 21칸 63.5x38 -> 63.5x38.1
UPDATE label_specs s
INNER JOIN shop_products p ON p.spec_id = s.id
SET s.name = REPLACE(s.name, '63.5x38mm', '63.5x38.1mm'),
    s.width_mm = 63.50,
    s.height_mm = 38.10,
    s.v_gap_mm = 0.000,
    s.top_margin_mm = 15.875,
    s.updated_at = NOW()
WHERE p.sku IN ('LT307', 'IC307', 'LC307', 'AK307')
  AND s.width_mm = 63.50
  AND s.height_mm = 38.00;

-- 1칸 200x289 -> 199.9x289.05
UPDATE label_specs s
INNER JOIN shop_products p ON p.spec_id = s.id
SET s.name = REPLACE(s.name, '200x289mm', '199.9x289.05mm'),
    s.width_mm = 199.90,
    s.height_mm = 289.05,
    s.left_margin_mm = 5.400,
    s.top_margin_mm = 4.699,
    s.updated_at = NOW()
WHERE p.sku IN ('LN101R', 'LN101G', 'LN101Y', 'AP101Y', 'AP101G', 'AP101P', 'AP101B', 'AK101')
  AND s.width_mm = 200.00
  AND s.height_mm = 289.00;

-- 14칸 99.1x38 -> 99.06x38.1
UPDATE label_specs s
INNER JOIN shop_products p ON p.spec_id = s.id
SET s.name = REPLACE(s.name, '99.1x38mm', '99.06x38.1mm'),
    s.width_mm = 99.06,
    s.height_mm = 38.10,
    s.h_gap_mm = 2.540,
    s.v_gap_mm = 0.000,
    s.left_margin_mm = 5.086,
    s.top_margin_mm = 15.875,
    s.updated_at = NOW()
WHERE p.sku = 'AK207'
  AND s.width_mm = 99.10
  AND s.height_mm = 38.00;

ALTER TABLE shop_products
    ADD COLUMN display_width_mm DECIMAL(8,2) NULL COMMENT '상품 상세 표기 가로(mm). NULL이면 규격 치수' AFTER spec_id,
    ADD COLUMN display_height_mm DECIMAL(8,2) NULL COMMENT '상품 상세 표기 세로(mm). NULL이면 규격 치수' AFTER display_width_mm;

UPDATE shop_products SET display_width_mm = 200.00, display_height_mm = 143.50, updated_at = NOW()
WHERE sku IN ('LT102', 'IC102', 'LC102', 'AK102');

UPDATE shop_products SET display_width_mm = 99.10, display_height_mm = 67.70, updated_at = NOW()
WHERE sku = 'LT204';

UPDATE shop_products SET display_width_mm = 99.10, display_height_mm = 33.90, updated_at = NOW()
WHERE sku = 'LT208';

UPDATE shop_products SET display_width_mm = 63.50, display_height_mm = 38.00, updated_at = NOW()
WHERE sku IN ('LT307', 'IC307', 'LC307', 'AK307');

UPDATE shop_products SET display_width_mm = 200.00, display_height_mm = 289.00, updated_at = NOW()
WHERE sku IN ('LN101R', 'LN101G', 'LN101Y', 'AP101Y', 'AP101G', 'AP101P', 'AP101B', 'AK101');

UPDATE shop_products SET display_width_mm = 99.10, display_height_mm = 38.00, updated_at = NOW()
WHERE sku = 'AK207';
