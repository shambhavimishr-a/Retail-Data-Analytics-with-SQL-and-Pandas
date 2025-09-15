-- 16. RFM Analysis (Recency, Frequency, Monetary)
WITH customer_rfm AS (
  SELECT c.customer_id,
         MAX(o.order_datetime) AS last_order_date,
         COUNT(DISTINCT o.order_id) AS frequency,
         SUM(oi.quantity*oi.unit_price - oi.discount_amt + oi.tax_amt) AS monetary
  FROM customers c
  JOIN orders o ON c.customer_id = o.customer_id
  JOIN order_items oi ON o.order_id = oi.order_id
  GROUP BY c.customer_id
)
SELECT c.customer_id, c.first_name, c.last_name,
       CURRENT_DATE - DATE(last_order_date) AS recency_days,
       frequency, monetary
FROM customer_rfm c
ORDER BY monetary DESC
LIMIT 20;

-- 17. Cohort Analysis: Customers grouped by signup month
SELECT DATE_TRUNC('month', c.signup_at) AS cohort,
       DATE_TRUNC('month', o.order_datetime) AS order_month,
       COUNT(DISTINCT c.customer_id) AS num_customers
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY cohort, order_month
ORDER BY cohort, order_month;

-- 18. % of orders paid via COD that were refunded
SELECT ROUND(100.0 * SUM(CASE WHEN p.method='COD' AND r.refund_id IS NOT NULL THEN 1 ELSE 0 END) /
                    NULLIF(SUM(CASE WHEN p.method='COD' THEN 1 ELSE 0 END),0),2) AS cod_refund_rate
FROM payments p
LEFT JOIN refunds r ON p.payment_id = r.payment_id;

-- 19. Average delivery time per carrier
SELECT carrier,
       ROUND(AVG(delivered_at - shipped_at),2) AS avg_delivery_days
FROM shipments
WHERE delivered_at IS NOT NULL
GROUP BY carrier;

-- 20. Pareto Analysis (80-20 Rule): top products contributing 80% of revenue
WITH product_sales AS (
  SELECT p.product_name, SUM(oi.quantity*oi.unit_price) AS total_sales
  FROM order_items oi
  JOIN products p ON oi.product_id = p.product_id
  GROUP BY p.product_name
),
ranked AS (
  SELECT product_name, total_sales,
         SUM(total_sales) OVER (ORDER BY total_sales DESC) AS running_sales,
         SUM(total_sales) OVER () AS total_all
  FROM product_sales
)
SELECT product_name, total_sales,
       ROUND(running_sales/total_all*100,2) AS cum_pct
FROM ranked
WHERE running_sales/total_all <= 0.8
ORDER BY total_sales DESC;

--21.How many customers churned last month?
-- churned = had orders before last month, but no orders in last 30 days
WITH last_30 AS (
  SELECT DISTINCT customer_id FROM orders
  WHERE order_datetime >= CURRENT_DATE - INTERVAL '30 days'
),
prev_customers AS (
  SELECT DISTINCT customer_id FROM orders
  WHERE order_datetime < CURRENT_DATE - INTERVAL '30 days'
)
SELECT COUNT(*) AS churned_customers
FROM prev_customers pc
LEFT JOIN last_30 l ON pc.customer_id = l.customer_id
WHERE l.customer_id IS NULL;


--22.Which products have the highest return rate and % of revenue loss?
WITH sold AS (
  SELECT product_id, SUM(quantity) AS qty_sold, SUM(quantity * unit_price - discount_amt + tax_amt) AS revenue
  FROM order_items
  GROUP BY product_id
),
ret AS (
  SELECT product_id, SUM(quantity_returned) AS qty_returned
  FROM returns
  GROUP BY product_id
)
SELECT p.product_id, p.product_name,
       s.qty_sold, COALESCE(r.qty_returned,0) AS qty_returned,
       ROUND(100.0 * COALESCE(r.qty_returned,0) / NULLIF(s.qty_sold,0), 2) AS return_pct,
       ROUND(COALESCE(r.qty_returned,0) * p.unit_price,2) AS approx_revenue_lost
FROM products p
JOIN sold s ON p.product_id = s.product_id
LEFT JOIN ret r ON p.product_id = r.product_id
ORDER BY return_pct DESC NULLS LAST
LIMIT 20;

---23.Top cities by YoY revenue growth (last 12 months vs previous 12 months).
WITH rev AS (
  SELECT DATE_TRUNC('year', o.order_datetime) AS year, c.city,
         SUM(oi.quantity*oi.unit_price - oi.discount_amt + oi.tax_amt) AS revenue
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN customers c ON o.customer_id = c.customer_id
  WHERE o.order_datetime >= (CURRENT_DATE - INTERVAL '2 years')
  GROUP BY year, c.city
)
SELECT cur.city,
       COALESCE(prev.revenue,0) AS prev_year_rev,
       COALESCE(cur.revenue,0) AS cur_year_rev,
       ROUND(100.0 * (cur.revenue - COALESCE(prev.revenue,0)) / NULLIF(COALESCE(prev.revenue,0),0),2) AS pct_growth
FROM (
  SELECT city, revenue FROM rev WHERE year = DATE_TRUNC('year', CURRENT_DATE - INTERVAL '1 year')
) prev
FULL JOIN (
  SELECT city, revenue FROM rev WHERE year = DATE_TRUNC('year', CURRENT_DATE)
) cur USING (city)
ORDER BY pct_growth DESC NULLS LAST
LIMIT 20;

--24.Top customers by repeat purchase rate (>=2 orders)
WITH cust_orders AS (
  SELECT customer_id, COUNT(DISTINCT order_id) AS orders_count
  FROM orders
  GROUP BY customer_id
)
SELECT c.customer_id, c.first_name, c.last_name, co.orders_count
FROM cust_orders co
JOIN customers c ON co.customer_id = c.customer_id
WHERE co.orders_count >= 2
ORDER BY co.orders_count DESC
LIMIT 50;

