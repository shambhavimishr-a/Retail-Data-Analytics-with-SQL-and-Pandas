-- step03_categories_suppliers.sql

CREATE TABLE IF NOT EXISTS categories (
    category_id     INT PRIMARY KEY,
    category_name   TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS suppliers (
    supplier_id     INT PRIMARY KEY,
    supplier_name   TEXT NOT NULL,
    contact_email   TEXT,
    phone           TEXT,
    country         TEXT
);

select * from categories, suppliers;

-- Later, products table can be ALTERed to add:
-- ALTER TABLE products ADD COLUMN category_id INT REFERENCES categories(category_id);
-- ALTER TABLE products ADD COLUMN supplier_id INT REFERENCES suppliers(supplier_id);