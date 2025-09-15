-- step02_products.sql
-- Products table. We'll add foreign keys to categories/suppliers in later steps.

CREATE TABLE IF NOT EXISTS products (
    product_id      INT PRIMARY KEY,
    sku             TEXT NOT NULL UNIQUE,
    product_name    TEXT NOT NULL,
    category        TEXT NOT NULL,
    subcategory     TEXT NOT NULL,
    brand           TEXT NOT NULL,
    model_number    TEXT,
    color           TEXT,
    weight_g        INT CHECK (weight_g >= 0),
    release_year    INT CHECK (release_year BETWEEN 2000 AND 2100),
    warranty_months INT CHECK (warranty_months >= 0),
    wireless        TEXT,
    resolution      TEXT,
    unit_price      NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
    msrp            NUMERIC(12,2) CHECK (msrp >= 0),
    cost_price      NUMERIC(12,2) CHECK (cost_price >= 0),
    currency        TEXT DEFAULT 'INR',
    is_active       BOOLEAN DEFAULT TRUE,
    gst_rate_percent INT DEFAULT 18 CHECK (gst_rate_percent IN (0,5,12,18,28))
);

-- Indexes for common filters
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category, subcategory);
CREATE INDEX IF NOT EXISTS idx_products_brand ON products(brand);
CREATE INDEX IF NOT EXISTS idx_products_price ON products(unit_price);

select * from products
limit 30;

truncate products;

ALTER TABLE public.products
  ADD COLUMN category_id INT,
  ADD COLUMN supplier_id INT;

ALTER TABLE public.products
  ADD CONSTRAINT fk_products_category
  FOREIGN KEY (category_id) REFERENCES public.categories(category_id);

ALTER TABLE public.products
  ADD CONSTRAINT fk_products_supplier
  FOREIGN KEY (supplier_id) REFERENCES public.suppliers(supplier_id);



  UPDATE products p
SET category_id = c.category_id
FROM categories c
WHERE p.category = c.category_name;

UPDATE products p
SET supplier_id = s.supplier_id
FROM suppliers s
WHERE p.brand = split_part(s.supplier_name, ' ', 1);  -- rough match

ALTER TABLE products
  ADD CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES categories(category_id);

ALTER TABLE products
  ADD CONSTRAINT fk_products_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id);


UPDATE products SET brand = TRIM(brand);
UPDATE suppliers SET supplier_name = TRIM(supplier_name);

UPDATE products p
SET supplier_id = s.supplier_id
FROM suppliers s
WHERE p.supplier_id IS NULL
  AND UPPER(SPLIT_PART(s.supplier_name,' ',1)) = UPPER(p.brand);


WITH missing AS (
  SELECT DISTINCT p.brand
  FROM products p
  LEFT JOIN suppliers s
    ON UPPER(SPLIT_PART(s.supplier_name,' ',1)) = UPPER(p.brand)
       OR UPPER(s.supplier_name) = UPPER(p.brand)
  WHERE p.supplier_id IS NULL AND s.supplier_id IS NULL
),
id_base AS (
  SELECT COALESCE(MAX(supplier_id),0) AS start_id FROM suppliers
),
to_insert AS (
  SELECT
    (SELECT start_id FROM id_base) + ROW_NUMBER() OVER () AS supplier_id,
    m.brand || ' India' AS supplier_name,
    LOWER(REPLACE(m.brand,' ','_')) || '@example.com' AS contact_email,
    NULL::text AS phone,
    'India'::text AS country
  FROM missing m
)
INSERT INTO suppliers (supplier_id, supplier_name, contact_email, phone, country)
SELECT supplier_id, supplier_name, contact_email, phone, country
FROM to_insert;


UPDATE products p
SET supplier_id = s.supplier_id
FROM suppliers s
WHERE p.supplier_id IS NULL
  AND (
       UPPER(SPLIT_PART(s.supplier_name,' ',1)) = UPPER(p.brand)
    OR UPPER(s.supplier_name) = UPPER(p.brand)
  );



  SELECT COUNT(*) AS remaining_nulls FROM products WHERE supplier_id IS NULL;

-- Spot-check a few mappings
SELECT brand, supplier_id
FROM products
ORDER BY supplier_id NULLS LAST
LIMIT 25;






-- 1. Reset any bad mappings
UPDATE products SET category_id = NULL, supplier_id = NULL;

-- 2. Map categories correctly
-- Make sure categories table already has:
-- (1, 'Computers'), (2, 'Accessories'), (3, 'Mobiles & Tablets')
UPDATE products p
SET category_id = c.category_id
FROM categories c
WHERE p.category = c.category_name;

-- Check category distribution
SELECT category, COUNT(*) AS num_products, MIN(category_id), MAX(category_id)
FROM products
GROUP BY category
ORDER BY category;


-- 3. Map suppliers correctly
-- Match brand to supplier_name by prefix (e.g. brand='HP' → supplier_name='HP India')
UPDATE products p
SET supplier_id = s.supplier_id
FROM suppliers s
WHERE p.supplier_id IS NULL
  AND UPPER(s.supplier_name) LIKE UPPER(p.brand || '%');

-- 4. Catch unmapped brands (manual step)
SELECT DISTINCT p.brand
FROM products p
LEFT JOIN suppliers s
  ON UPPER(s.supplier_name) LIKE UPPER(p.brand || '%')
WHERE p.supplier_id IS NULL
ORDER BY p.brand;

-- For any brands still NULL, either:
-- (a) Insert them into suppliers:
-- INSERT INTO suppliers (supplier_name, contact_email, country)
-- VALUES ('Amazfit India','support@amazfit.in','India');
--
-- (b) Then re-run the supplier update above.

-- 5. Verify results
SELECT brand, COUNT(*) AS num_products, MIN(supplier_id), MAX(supplier_id)
FROM products
GROUP BY brand
ORDER BY brand;




BEGIN;

-- 1) Drop FK constraints if they exist (safe no-ops if they don't)
ALTER TABLE IF EXISTS public.products DROP CONSTRAINT IF EXISTS fk_products_category;
ALTER TABLE IF EXISTS public.products DROP CONSTRAINT IF EXISTS fk_products_supplier;

-- Fallback: drop any other FKs on products (covers unknown constraint names)
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT conname
    FROM pg_constraint c
    JOIN pg_class t ON t.oid = c.conrelid
    WHERE t.relname = 'products' AND c.contype = 'f'
  LOOP
    EXECUTE format('ALTER TABLE public.products DROP CONSTRAINT %I', r.conname);
  END LOOP;
END $$;

-- 2) Drop the columns
ALTER TABLE public.products DROP COLUMN IF EXISTS category_id;
ALTER TABLE public.products DROP COLUMN IF EXISTS supplier_id;

COMMIT;


SELECT column_name
FROM information_schema.columns
WHERE table_schema='public'
  AND table_name='products'
  AND column_name IN ('category_id','supplier_id');


  select * from products limit 10;


