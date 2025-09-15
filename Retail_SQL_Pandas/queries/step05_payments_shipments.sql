-- step05_payments_shipments.sql

CREATE TABLE IF NOT EXISTS payments (
    payment_id  INT PRIMARY KEY,
    order_id    INT NOT NULL,
    method      TEXT NOT NULL CHECK (method IN ('UPI','Card','COD','NetBanking')),
    amount      NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
    paid_at     TIMESTAMP,
    status      TEXT NOT NULL CHECK (status IN ('Authorized','Captured','Refunded','Failed'))
);
CREATE INDEX IF NOT EXISTS idx_payments_order ON payments(order_id);

CREATE TABLE IF NOT EXISTS shipments (
    shipment_id INT PRIMARY KEY,
    order_id    INT NOT NULL,
    carrier     TEXT,
    tracking_no TEXT,
    shipped_at  TIMESTAMP,
    delivered_at TIMESTAMP,
    status      TEXT NOT NULL CHECK (status IN ('Shipped','Delivered'))
);
CREATE INDEX IF NOT EXISTS idx_shipments_order ON shipments(order_id);