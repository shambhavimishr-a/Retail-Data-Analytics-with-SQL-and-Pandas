-- step06_returns_refunds.sql

CREATE TABLE IF NOT EXISTS refunds (
    refund_id     INT PRIMARY KEY,
    order_id      INT NOT NULL,
    payment_id    INT, -- may be NULL if payment failed or not yet captured
    refund_amount NUMERIC(12,2) NOT NULL CHECK (refund_amount >= 0),
    refunded_at   TIMESTAMP,
    method        TEXT,  -- usually original payment method
    status        TEXT NOT NULL CHECK (status IN ('Pending','Completed','Failed'))
);
CREATE INDEX IF NOT EXISTS idx_refunds_order ON refunds(order_id);
CREATE INDEX IF NOT EXISTS idx_refunds_payment ON refunds(payment_id);

CREATE TABLE IF NOT EXISTS returns (
    return_id          INT PRIMARY KEY,
    order_id           INT NOT NULL,
    line_number        INT NOT NULL,
    product_id         INT NOT NULL,
    quantity_returned  INT NOT NULL CHECK (quantity_returned > 0),
    reason             TEXT,
    initiated_at       TIMESTAMP NOT NULL,
    approved_at        TIMESTAMP,
    status             TEXT NOT NULL CHECK (status IN ('Initiated','Approved','Rejected','Refunded')),
    refund_id          INT
);
CREATE INDEX IF NOT EXISTS idx_returns_order ON returns(order_id);
CREATE INDEX IF NOT EXISTS idx_returns_refund ON returns(refund_id);

--Suggested FKs if base tables exist:
ALTER TABLE returns ADD CONSTRAINT fk_returns_order      FOREIGN KEY (order_id)  REFERENCES orders(order_id);
ALTER TABLE returns ADD CONSTRAINT fk_returns_item       FOREIGN KEY (order_id, line_number) REFERENCES order_items(order_id, line_number);
ALTER TABLE returns ADD CONSTRAINT fk_returns_product    FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE returns ADD CONSTRAINT fk_returns_refund     FOREIGN KEY (refund_id)  REFERENCES refunds(refund_id);
ALTER TABLE refunds ADD CONSTRAINT fk_refunds_order      FOREIGN KEY (order_id)   REFERENCES orders(order_id);
ALTER TABLE refunds ADD CONSTRAINT fk_refunds_payment    FOREIGN KEY (payment_id) REFERENCES payments(payment_id);

select * from returns;





BEGIN;

-- If a previous table exists (maybe with different columns/constraints)
DROP TABLE IF EXISTS public.returns;

CREATE TABLE public.returns (
    return_id          INT PRIMARY KEY,
    order_id           INT NOT NULL,
    line_number        INT NOT NULL,
    product_id         INT NOT NULL,
    quantity_returned  INT NOT NULL CHECK (quantity_returned > 0),
    reason             TEXT,
    initiated_at       TIMESTAMP NOT NULL,
    approved_at        TIMESTAMP,
    status             TEXT NOT NULL CHECK (status IN ('Initiated','Approved','Rejected','Refunded')),
    refund_id          INT
);

COMMIT;



-- adjust the path to your file
\copy public.returns(
  return_id, order_id, line_number, product_id, quantity_returned,
  reason, initiated_at, approved_at, status, refund_id
) FROM '/Users/shambhavimishra/Downloads/returns.csv'
  WITH (FORMAT csv, HEADER true, NULL '');

SELECT * FROM public.returns;

