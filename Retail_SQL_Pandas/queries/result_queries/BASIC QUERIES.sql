-- 1. List all customers from Pune
SELECT customer_id, first_name, last_name, city
FROM customers
WHERE city = 'Pune';

-- 2. Show all products in the "Computers" category priced above ₹50,000
SELECT product_id, product_name, brand, unit_price
FROM products
WHERE category = 'Computers'
  AND unit_price > 50000;

-- 3. Display the 10 most recent orders
SELECT order_id, order_code, order_datetime, status
FROM orders
ORDER BY order_datetime DESC
LIMIT 10;

-- 4. Find all orders with status = 'Cancelled'
SELECT order_id, order_code, customer_id, order_datetime
FROM orders
WHERE status = 'Cancelled';

-- 5. List all unique cities where customers live
SELECT DISTINCT city
FROM customers
ORDER BY city;
