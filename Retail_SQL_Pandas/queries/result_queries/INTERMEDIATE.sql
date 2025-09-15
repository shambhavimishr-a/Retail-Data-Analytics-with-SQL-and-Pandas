-- 6. Show all orders along with the customer’s name
SELECT o.order_id, o.order_code, o.order_datetime,
       c.first_name || ' ' || c.last_name AS customer_name
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
ORDER BY o.order_datetime DESC
LIMIT 20;

-- 7. Get the top 5 products by total sales value
SELECT p.product_name,
       SUM(oi.quantity * oi.unit_price) AS total_sales
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_sales DESC
LIMIT 5;

-- 8. Find the number of orders placed per city
SELECT c.city, COUNT(DISTINCT o.order_id) AS num_orders
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.city
ORDER BY num_orders DESC;

-- 9. Show the average unit price per product category
SELECT category, ROUND(AVG(unit_price), 2) AS avg_price
FROM products
GROUP BY category
ORDER BY avg_price DESC;

-- 10. Get the total revenue per order (use order_items)
SELECT o.order_id, o.order_code,
       SUM(oi.quantity * oi.unit_price - oi.discount_amt + oi.tax_amt) AS order_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.order_code
ORDER BY order_revenue DESC
LIMIT 10;

-- 11. Find the most common payment method
SELECT method ,COUNT(*) AS num_payments
FROM payments
GROUP BY method
ORDER BY num_payments DESC
LIMIT 1;

--SELECT * FROM payments

-- 12. Count how many orders have shipments
SELECT COUNT(DISTINCT order_id) AS orders_with_shipments
FROM shipments;

-- 13. Show all products that have never been ordered
SELECT p.product_id, p.product_name, p.category, p.brand
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL;

-- 14. Get the total tax collected per month
SELECT DATE_TRUNC('month', o.order_datetime) AS month,
       SUM(oi.tax_amt) AS total_tax
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY month
ORDER BY month;

-- 15. Find the number of refunds issued per payment method
SELECT p.method, COUNT(r.refund_id) AS num_refunds
FROM refunds r
JOIN payments p ON r.payment_id = p.payment_id
GROUP BY p.method
ORDER BY num_refunds DESC;

-- 11. Customers who spent more than the average
WITH customer_spend AS (
  SELECT o.customer_id,
         SUM(oi.quantity*oi.unit_price - oi.discount_amt + oi.tax_amt) AS total_spent
  FROM orders o
  JOIN order_items oi ON o.order_id = oi.order_id
  GROUP BY o.customer_id
)
SELECT c.customer_id, c.first_name, c.last_name, cs.total_spent
FROM customer_spend cs
JOIN customers c ON cs.customer_id = c.customer_id
WHERE cs.total_spent > (SELECT AVG(total_spent) FROM customer_spend)
ORDER BY cs.total_spent DESC
LIMIT 20;

-- 12. Top 3 products by sales in each category
SELECT category, product_name, total_sales
FROM (
  SELECT p.category, p.product_name,
         SUM(oi.quantity*oi.unit_price) AS total_sales,
         RANK() OVER (PARTITION BY p.category ORDER BY SUM(oi.quantity*oi.unit_price) DESC) AS rnk
  FROM order_items oi
  JOIN products p ON oi.product_id = p.product_id
  GROUP BY p.category, p.product_name
) ranked
WHERE rnk <= 3
ORDER BY category, total_sales DESC;

-- 13. Customers with more than 5 orders
SELECT c.customer_id, c.first_name, c.last_name,
       COUNT(o.order_id) AS order_count
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id
HAVING COUNT(o.order_id) > 5
ORDER BY order_count DESC;

-- 14. Latest order per customer
SELECT DISTINCT ON (o.customer_id)
       o.customer_id, c.first_name, c.last_name,
       o.order_id, o.order_datetime
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
ORDER BY o.customer_id, o.order_datetime DESC;

-- 15. Return rate per product
SELECT p.product_name,
       SUM(r.quantity_returned)::DECIMAL / NULLIF(SUM(oi.quantity),0) AS return_rate
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN returns r ON oi.order_id = r.order_id AND oi.line_number = r.line_number
GROUP BY p.product_name
ORDER BY return_rate DESC NULLS LAST
LIMIT 10;

