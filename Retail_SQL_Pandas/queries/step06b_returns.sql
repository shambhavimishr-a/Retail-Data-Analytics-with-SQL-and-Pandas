-- step06b_returns.sql (simplified, NULL-safe for pgAdmin imports)

CREATE TABLE IF NOT EXISTS returns (
    return_id          INT PRIMARY KEY,
    order_id           INT NOT NULL,
    line_number        INT NOT NULL,
    product_id         INT NOT NULL,
    quantity_returned  INT NOT NULL CHECK (quantity_returned > 0),
    reason             TEXT,
    initiated_at       TIMESTAMP NOT NULL,
    approved_at        TIMESTAMP NOT NULL,
    status             TEXT NOT NULL CHECK (status IN ('Approved','Refunded'))
);

CREATE INDEX IF NOT EXISTS idx_returns_order ON returns(order_id);
CREATE INDEX IF NOT EXISTS idx_returns_item  ON returns(order_id, line_number);
CREATE INDEX IF NOT EXISTS idx_returns_prod  ON returns(product_id);

-- Optional FKs (run only after base tables are present and clean):
-- ALTER TABLE returns ADD CONSTRAINT fk_returns_order  FOREIGN KEY (order_id) REFERENCES orders(order_id);
-- ALTER TABLE returns ADD CONSTRAINT fk_returns_item   FOREIGN KEY (order_id, line_number) REFERENCES order_items(order_id, line_number);
-- ALTER TABLE returns ADD CONSTRAINT fk_returns_prod   FOREIGN KEY (product_id) REFERENCES products(product_id);