-- General KPI check

-- 1. Total KPI Overview
SELECT 
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(i.price), 2) AS total_revenue,
    COUNT(DISTINCT o.customer_id) AS unique_customers,
    ROUND(AVG(i.price), 2) AS avg_spent_per_order
FROM order_items i
JOIN orders o ON i.order_id = o.order_id
WHERE o.is_valid_sale = 1;


-- 2. Monthly Revenue and Order Growth 


SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS sale_month,
    t.product_category_name_english AS category, -- Changed to the English translation column
    ROUND(SUM(i.price), 2) AS revenue,
    COUNT(o.order_id) AS order_volume
FROM orders o
JOIN order_items i ON o.order_id = i.order_id
JOIN products p ON i.product_id = p.product_id
-- Added Join to the translation table
JOIN product_category_name t ON p.product_category_name = t.product_category_name
WHERE o.is_valid_sale = 1
GROUP BY sale_month, category
ORDER BY sale_month;

-- 3. Top States by Revenue & Volume

SELECT 
    c.customer_state,
    ROUND(SUM(i.price), 2) AS total_revenue,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(i.price) / COUNT(DISTINCT o.customer_id), 2) AS avg_customer_value
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items i ON o.order_id = i.order_id
WHERE o.is_valid_sale = 1
GROUP BY c.customer_state
ORDER BY total_revenue DESC;

-- 4. Top 10 Categories by Revenue

SELECT 
    t.product_category_name_english AS category,
    COUNT(o.order_id) AS units_sold,
    ROUND(SUM(i.price), 2) AS total_revenue,
    ROUND(AVG(i.price), 2) AS avg_item_price
FROM order_items i
JOIN products p ON i.product_id = p.product_id
JOIN product_category_name t ON p.product_category_name = t.product_category_name
JOIN orders o ON i.order_id = o.order_id
WHERE o.is_valid_sale = 1
GROUP BY category
ORDER BY total_revenue DESC
LIMIT 10;

-- 5. Average Delivery Time (Days) by Top States

SELECT 
    c.customer_state,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 1) AS avg_delivery_days,
    ROUND(AVG(DATEDIFF(o.order_estimated_delivery_date, o.order_purchase_timestamp)), 1) AS avg_estimated_days,
    -- Calculate the "Disappointment Gap"
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date)), 1) AS avg_days_late
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered' 
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC;


-- 6. Payment Type Popularity & Average Order Value

SELECT 
    p.payment_type,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(p.payment_value), 2) AS total_revenue,
    ROUND(AVG(p.payment_value), 2) AS avg_payment_value
FROM order_payments p
JOIN orders o ON p.order_id = o.order_id
WHERE o.is_valid_sale = 1
GROUP BY p.payment_type
ORDER BY total_revenue DESC;

-- 7. Customer Loyalty: One-Time vs. Repeat Buyers

SELECT 
    CASE WHEN order_count > 1 THEN 'Repeat Customer' ELSE 'One-Time Customer' END AS loyalty_type,
    COUNT(*) AS total_customers,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT customer_unique_id) FROM customers), 2) AS percentage
FROM (
    SELECT c.customer_unique_id, COUNT(o.order_id) AS order_count
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.is_valid_sale = 1
    GROUP BY c.customer_unique_id
) AS customer_stats
GROUP BY loyalty_type;

-- 8. Review Scores for Repeat vs One-Time Customers

SELECT 
    CASE WHEN order_count > 1 THEN 'Repeat Customer' ELSE 'One-Time Customer' END AS loyalty_type,
    ROUND(AVG(review_score), 2) AS avg_review_score
FROM (
    SELECT c.customer_unique_id, COUNT(o.order_id) AS order_count, AVG(r.review_score) AS review_score
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_reviews r ON o.order_id = r.order_id
    WHERE o.is_valid_sale = 1
    GROUP BY c.customer_unique_id
) AS final_stats
GROUP BY loyalty_type;

-- 9. Top 10 Worst Rated Categories

SELECT 
    t.product_category_name_english AS category,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    COUNT(o.order_id) AS total_orders
FROM order_items i
JOIN products p ON i.product_id = p.product_id
JOIN product_category_name t ON p.product_category_name = t.product_category_name
JOIN orders o ON i.order_id = o.order_id
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.is_valid_sale = 1
GROUP BY category
HAVING total_orders >= 50 
ORDER BY avg_review_score ASC
LIMIT 10;

