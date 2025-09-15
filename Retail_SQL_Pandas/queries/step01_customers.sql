-- step01_customers.sql
-- DDL for customers table (+ suggested load command).

CREATE TABLE IF NOT EXISTS customers (
    customer_id         INT PRIMARY KEY,
    customer_code       TEXT NOT NULL UNIQUE,
    first_name          TEXT NOT NULL,
    last_name           TEXT NOT NULL,
    gender              TEXT CHECK (gender IN ('Male','Female','Other')),
    email               TEXT NOT NULL UNIQUE,
    phone               TEXT UNIQUE,
    city                TEXT,
    state               TEXT,
    country             TEXT,
    postal_code         TEXT,
    birth_date          DATE,
    signup_at           TIMESTAMP,
    segment             TEXT,
    is_active           BOOLEAN DEFAULT TRUE,
    opted_in_marketing  BOOLEAN DEFAULT FALSE
);

-- Helpful indexes
CREATE INDEX IF NOT EXISTS idx_customers_city ON customers(city);
CREATE INDEX IF NOT EXISTS idx_customers_state ON customers(state);
CREATE INDEX IF NOT EXISTS idx_customers_segment ON customers(segment);

-- Suggested bulk load (psql):
-- \copy customers FROM 'customers_20000.csv' WITH CSV HEADER;


select * from customers
limit 10;

--truncate table customers;


