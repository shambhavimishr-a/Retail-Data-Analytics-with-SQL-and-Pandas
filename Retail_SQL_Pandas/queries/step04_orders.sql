-- step04_orders.sql
CREATE TABLE IF NOT EXISTS orders (
    order_id        INT PRIMARY KEY,
    order_code      TEXT NOT NULL UNIQUE,
    customer_id     INT NOT NULL,
    order_datetime  TIMESTAMP NOT NULL,
    status          TEXT NOT NULL CHECK (status IN ('Pending','Paid','Shipped','Delivered','Cancelled'))
);
CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_datetime ON orders(order_datetime);

CREATE TABLE IF NOT EXISTS order_items (
    order_id        INT NOT NULL,
    line_number     INT NOT NULL,
    product_id      INT NOT NULL,
    quantity        INT NOT NULL CHECK (quantity > 0),
    unit_price      NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
    discount_amt    NUMERIC(12,2) DEFAULT 0 CHECK (discount_amt >= 0),
    tax_amt         NUMERIC(12,2) DEFAULT 0 CHECK (tax_amt >= 0),
    PRIMARY KEY(order_id, line_number)
);
CREATE INDEX IF NOT EXISTS idx_order_items_product ON order_items(product_id);