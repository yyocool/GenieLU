-- 091_shop_product_display_sizes.sql
-- 쇼핑 상세 표기치수 추가 반영. 편집기 label_specs 는 변경하지 않는다.
-- (.dbSchema/updateSQL_261119_3.sql 과 동일)

ALTER TABLE shop_products
    ADD COLUMN display_size_text VARCHAR(40) NULL COMMENT '상품 상세 표기 규격 문구(2set 등). 있으면 mm 대신 표시' AFTER display_height_mm;

UPDATE shop_products
SET display_width_mm = 200.00, display_height_mm = 289.00, display_size_text = NULL, updated_at = NOW()
WHERE sku IN ('A101', 'LG101', 'LW101', 'LT101', 'LN101R', 'LN101G', 'LN101Y',
              'AP101Y', 'AP101G', 'AP101P', 'AP101B', 'AK101');

UPDATE shop_products
SET display_width_mm = 200.00, display_height_mm = 143.50, display_size_text = NULL, updated_at = NOW()
WHERE sku IN ('A102', 'LG102', 'LW102', 'LT102', 'IC102', 'LC102', 'AK102');

UPDATE shop_products
SET display_width_mm = 98.70, display_height_mm = 139.00, display_size_text = NULL, updated_at = NOW()
WHERE sku IN ('A202', 'LW202');

UPDATE shop_products
SET display_width_mm = 99.10, display_height_mm = 93.00, display_size_text = NULL, updated_at = NOW()
WHERE sku = 'A203';

UPDATE shop_products
SET display_width_mm = 89.00, display_height_mm = 52.00, display_size_text = NULL, updated_at = NOW()
WHERE sku IN ('A205', 'LG205');

UPDATE shop_products
SET display_width_mm = 99.10, display_height_mm = 38.00, display_size_text = NULL, updated_at = NOW()
WHERE sku IN ('A207', 'AK207');

UPDATE shop_products
SET display_width_mm = 63.50, display_height_mm = 38.00, display_size_text = NULL, updated_at = NOW()
WHERE sku IN ('A307', 'LG307', 'LW307', 'LT307', 'IC307', 'LC307', 'AK307');

UPDATE shop_products
SET display_width_mm = 64.00, display_height_mm = 34.00, display_size_text = NULL, updated_at = NOW()
WHERE sku = 'A308';

UPDATE shop_products
SET display_width_mm = 62.70, display_height_mm = 30.00, display_size_text = NULL, updated_at = NOW()
WHERE sku = 'A309';

UPDATE shop_products
SET display_width_mm = 47.00, display_height_mm = 27.00, display_size_text = NULL, updated_at = NOW()
WHERE sku IN ('A410', 'LW410');

UPDATE shop_products
SET display_width_mm = 38.00, display_height_mm = 19.00, display_size_text = NULL, updated_at = NOW()
WHERE sku IN ('A512', 'LW512');

UPDATE shop_products
SET display_width_mm = 38.00, display_height_mm = 21.10, display_size_text = NULL, updated_at = NOW()
WHERE sku = 'A513';

UPDATE shop_products
SET display_width_mm = NULL, display_height_mm = NULL, display_size_text = '4set', updated_at = NOW()
WHERE sku = 'AD104';

UPDATE shop_products
SET display_width_mm = NULL, display_height_mm = NULL, display_size_text = '2set', updated_at = NOW()
WHERE sku = 'AD102';
