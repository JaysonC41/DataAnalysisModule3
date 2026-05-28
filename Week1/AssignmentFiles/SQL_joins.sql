USE coffeeshop_db;

-- =========================================================
-- JOINS & RELATIONSHIPS PRACTICE
-- =========================================================

-- Q1) Join products to categories: list product_name, category_name, price.

SELECT 
    p.name AS product_name,
    c.name AS category_name,
    p.price
FROM products p
INNER JOIN categories c ON p.category_id = c.category_id
ORDER BY c.name, p.name;


-- Q2) For each order item, show: order_id, order_datetime, store_name,
--     product_name, quantity, line_total (= quantity * products.price).
--     Sort by order_datetime, then order_id.

SELECT 
    oi.order_id,
    o.order_datetime,
    s.name AS store_name,
    p.name AS product_name,
    oi.quantity,
    (oi.quantity * p.price) AS line_total
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN stores s ON o.store_id = s.store_id
ORDER BY o.order_datetime, o.order_id;

-- Q3) Customer order history (PAID only):
--     For each order, show customer_name, store_name, order_datetime,
--     order_total (= SUM(quantity * products.price) per order).

SELECT 
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    s.name AS store_name,
    o.order_datetime,
    SUM(oi.quantity * p.price) AS order_total
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN stores s ON o.store_id = s.store_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.status = 'paid'
GROUP BY o.order_id, c.first_name, c.last_name, s.name, o.order_datetime
ORDER BY o.order_datetime;

-- Q4) Left join to find customers who have never placed an order.
--     Return first_name, last_name, city, state.

SELECT 
    c.first_name,
    c.last_name,
    c.city,
    c.state
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- Q5) For each store, list the top-selling product by units (PAID only).
--     Return store_name, product_name, total_units.
--     Hint: Use a window function (ROW_NUMBER PARTITION BY store) or a correlated subquery.

WITH store_product_sales AS (
    SELECT 
        s.store_id,
        s.name AS store_name,
        p.product_id,
        p.name AS product_name,
        SUM(oi.quantity) AS total_units,
        ROW_NUMBER() OVER (PARTITION BY s.store_id ORDER BY SUM(oi.quantity) DESC) AS rank_num
    FROM stores s
    JOIN orders o ON s.store_id = o.store_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    WHERE o.status = 'paid'
    GROUP BY s.store_id, s.name, p.product_id, p.name
)
SELECT store_name, product_name, total_units
FROM store_product_sales
WHERE rank_num = 1;


-- Q6) Inventory check: show rows where on_hand < 12 in any store.
--     Return store_name, product_name, on_hand.

SELECT 
    s.name AS store_name,
    p.name AS product_name,
    i.on_hand
FROM inventory i
JOIN stores s ON i.store_id = s.store_id
JOIN products p ON i.product_id = p.product_id
WHERE i.on_hand < 12
ORDER BY i.on_hand, s.name, p.name;

-- Q7) Manager roster: list each store's manager_name and hire_date.
--     (Assume title = 'Manager').

SELECT 
    s.name AS store_name,
    CONCAT(e.first_name, ' ', e.last_name) AS manager_name,
    e.hire_date
FROM stores s
JOIN employees e ON s.store_id = e.store_id
WHERE e.title = 'Manager'
ORDER BY s.name;

-- Q8) Using a subquery/CTE: list products whose total PAID revenue is above
--     the average PAID product revenue. Return product_name, total_revenue.

WITH product_revenue AS (
    SELECT 
        p.product_id,
        p.name AS product_name,
        SUM(oi.quantity * p.price) AS total_revenue
    FROM products p
    JOIN order_items oi ON p.product_id = oi.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.status = 'paid'
    GROUP BY p.product_id, p.name
)
SELECT product_name, total_revenue
FROM product_revenue
WHERE total_revenue > (SELECT AVG(total_revenue) FROM product_revenue)
ORDER BY total_revenue DESC;

-- Q9) Churn-ish check: list customers with their last PAID order date.
--     If they have no PAID orders, show NULL.
--     Hint: Put the status filter in the LEFT JOIN's ON clause to preserve non-buyer rows.

SELECT 
    c.customer_id,
    c.first_name,
    c.last_name,
    MAX(o.order_datetime) AS last_paid_order_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id AND o.status = 'paid'
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY last_paid_order_date DESC;

-- Q10) Product mix report (PAID only):
--     For each store and category, show total units and total revenue (= SUM(quantity * products.price)).

SELECT 
    s.name AS store_name,
    cat.name AS category_name,
    SUM(oi.quantity) AS total_units,
    SUM(oi.quantity * p.price) AS total_revenue
FROM stores s
JOIN orders o ON s.store_id = o.store_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN categories cat ON p.category_id = cat.category_id
WHERE o.status = 'paid'
GROUP BY s.store_id, s.name, cat.category_id, cat.name
ORDER BY s.name, total_revenue DESC;
