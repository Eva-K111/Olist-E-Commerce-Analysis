SET SQL_SAFE_UPDATES = 0;

DESCRIBE orders;

-- Checking for nulls


-- 1. CUSTOMERS
SELECT 'customers' AS tbl, 'customer_id' AS col, COUNT(*) FROM customers WHERE customer_id IS NULL UNION ALL
SELECT 'customers', 'customer_unique_id', COUNT(*) FROM customers WHERE customer_unique_id IS NULL UNION ALL
SELECT 'customers', 'customer_zip_code_prefix', COUNT(*) FROM customers WHERE customer_zip_code_prefix IS NULL UNION ALL
SELECT 'customers', 'customer_city', COUNT(*) FROM customers WHERE customer_city IS NULL UNION ALL
SELECT 'customers', 'customer_state', COUNT(*) FROM customers WHERE customer_state IS NULL UNION ALL

-- 2. GEOLOCATION
SELECT 'geolocation', 'zip_code_prefix', COUNT(*) FROM geolocation WHERE geolocation_zip_code_prefix IS NULL UNION ALL
SELECT 'geolocation', 'lat', COUNT(*) FROM geolocation WHERE geolocation_lat IS NULL UNION ALL
SELECT 'geolocation', 'lng', COUNT(*) FROM geolocation WHERE geolocation_lng IS NULL UNION ALL
SELECT 'geolocation', 'city', COUNT(*) FROM geolocation WHERE geolocation_city IS NULL UNION ALL
SELECT 'geolocation', 'state', COUNT(*) FROM geolocation WHERE geolocation_state IS NULL UNION ALL

-- 3. ORDERS
SELECT 'orders', 'order_id', COUNT(*) FROM orders WHERE order_id IS NULL UNION ALL
SELECT 'orders', 'customer_id', COUNT(*) FROM orders WHERE customer_id IS NULL UNION ALL
SELECT 'orders', 'status', COUNT(*) FROM orders WHERE order_status IS NULL UNION ALL
SELECT 'orders', 'purchase_ts', COUNT(*) FROM orders WHERE order_purchase_timestamp IS NULL UNION ALL
SELECT 'orders', 'approved_at', COUNT(*) FROM orders WHERE order_approved_at IS NULL UNION ALL
SELECT 'orders', 'delivered_carrier', COUNT(*) FROM orders WHERE order_delivered_carrier_date IS NULL UNION ALL
SELECT 'orders', 'delivered_customer', COUNT(*) FROM orders WHERE order_delivered_customer_date IS NULL UNION ALL
SELECT 'orders', 'estimated_delivery', COUNT(*) FROM orders WHERE order_estimated_delivery_date IS NULL UNION ALL

-- 4. ORDER_ITEMS
SELECT 'order_items', 'order_id', COUNT(*) FROM order_items WHERE order_id IS NULL UNION ALL
SELECT 'order_items', 'product_id', COUNT(*) FROM order_items WHERE product_id IS NULL UNION ALL
SELECT 'order_items', 'seller_id', COUNT(*) FROM order_items WHERE seller_id IS NULL UNION ALL
SELECT 'order_items', 'price', COUNT(*) FROM order_items WHERE price IS NULL UNION ALL
SELECT 'order_items', 'freight_value', COUNT(*) FROM order_items WHERE freight_value IS NULL UNION ALL

-- 5. PRODUCTS
SELECT 'products', 'product_id', COUNT(*) FROM products WHERE product_id IS NULL UNION ALL
SELECT 'products', 'category_name', COUNT(*) FROM products WHERE product_category_name IS NULL UNION ALL
SELECT 'products', 'weight_g', COUNT(*) FROM products WHERE product_weight_g IS NULL UNION ALL
SELECT 'products', 'length_cm', COUNT(*) FROM products WHERE product_length_cm IS NULL UNION ALL
SELECT 'products', 'height_cm', COUNT(*) FROM products WHERE product_height_cm IS NULL UNION ALL
SELECT 'products', 'width_cm', COUNT(*) FROM products WHERE product_width_cm IS NULL UNION ALL

-- 6. ORDER_PAYMENTS
SELECT 'order_payments', 'order_id', COUNT(*) FROM order_payments WHERE order_id IS NULL UNION ALL
SELECT 'order_payments', 'payment_type', COUNT(*) FROM order_payments WHERE payment_type IS NULL UNION ALL
SELECT 'order_payments', 'payment_value', COUNT(*) FROM order_payments WHERE payment_value IS NULL UNION ALL

-- 7. ORDER_REVIEWS
SELECT 'order_reviews', 'review_id', COUNT(*) FROM order_reviews WHERE review_id IS NULL UNION ALL
SELECT 'order_reviews', 'review_score', COUNT(*) FROM order_reviews WHERE review_score IS NULL UNION ALL
SELECT 'order_reviews', 'comment_title', COUNT(*) FROM order_reviews WHERE review_comment_title IS NULL UNION ALL
SELECT 'order_reviews', 'comment_message', COUNT(*) FROM order_reviews WHERE review_comment_message IS NULL UNION ALL

-- 8. SELLERS
SELECT 'sellers', 'seller_id', COUNT(*) FROM sellers WHERE seller_id IS NULL UNION ALL
SELECT 'sellers', 'seller_zip_code_prefix', COUNT(*) FROM sellers WHERE seller_zip_code_prefix IS NULL UNION ALL

-- 9. CATEGORY TRANSLATION
SELECT 'product_category_name', 'name_portuguese', COUNT(*) FROM product_category_name WHERE product_category_name IS NULL UNION ALL
SELECT 'product_category_name', 'name_english', COUNT(*) FROM product_category_name WHERE product_category_name_english IS NULL;

-- Fixing nulls in order reviews

UPDATE order_reviews 
SET review_comment_message = 'No Message' 
WHERE review_comment_message IS NULL OR review_comment_message IN ('', ' ');

-- Fixing nulls in product category name

UPDATE products 
SET product_category_name = 'unknown' 
WHERE product_category_name IS NULL OR product_category_name IN ('', ' ');

-- Fixing nulls in comment title

UPDATE order_reviews
SET review_comment_title = 'No Title' 
WHERE review_comment_title IS NULL OR review_comment_title IN ('', ' ');

-- standardizing data for easy readability


INSERT IGNORE INTO product_category_name (product_category_name, product_category_name_english)
VALUES ('pc_gamer', 'pc gamer'), ('portateis_cozinha_e_preparadores_de_alimentos', 'kitchen portables');

UPDATE product_category_name 
SET product_category_name_english = REPLACE(product_category_name_english, '_', ' ');

-- Dealing with missing products weight

UPDATE products p
JOIN (
    SELECT product_category_name, AVG(product_weight_g) AS avg_weight
    FROM products
    WHERE product_weight_g > 0
    GROUP BY product_category_name
) AS category_avg ON p.product_category_name = category_avg.product_category_name
SET p.product_weight_g = category_avg.avg_weight
WHERE p.product_weight_g IS NULL OR p.product_weight_g = 0;


-- Flag cancelled sells that were still delivered

ALTER TABLE orders ADD COLUMN is_valid_sale TINYINT(1) DEFAULT 1;

UPDATE orders 
SET is_valid_sale = 0 
WHERE order_status = 'canceled' AND order_delivered_customer_date IS NOT NULL;

-- Standardize dates that physically couldn't happen

UPDATE orders 
SET order_delivered_customer_date = NULL, 
    order_delivered_carrier_date = NULL
WHERE order_delivered_carrier_date > order_delivered_customer_date;

-- Checking zero value payments

UPDATE order_payments 
SET payment_type = 'full_voucher' 
WHERE payment_value = 0 AND payment_type = 'voucher';

-- Deduplicating geolocation

CREATE TABLE geolocation_unique AS
SELECT 
    geolocation_zip_code_prefix,
    AVG(geolocation_lat) AS latitude,
    AVG(geolocation_lng) AS longitude,
    MAX(geolocation_city) AS city,
    MAX(geolocation_state) AS state
FROM geolocation
GROUP BY geolocation_zip_code_prefix;

ALTER TABLE geolocation_unique ADD PRIMARY KEY (geolocation_zip_code_prefix);

-- fixing orphan records in geolocation unique using a sub query

INSERT IGNORE INTO geolocation_unique (geolocation_zip_code_prefix, city, state, latitude, longitude)
SELECT DISTINCT seller_zip_code_prefix, 'unknown', 'UK', 0, 0
FROM sellers
WHERE seller_zip_code_prefix NOT IN (SELECT geolocation_zip_code_prefix FROM geolocation_unique);

INSERT IGNORE INTO geolocation_unique (geolocation_zip_code_prefix, city, state, latitude, longitude)
SELECT DISTINCT customer_zip_code_prefix, 'unknown', 'unknown', 0, 0
FROM customers
WHERE customer_zip_code_prefix NOT IN (SELECT geolocation_zip_code_prefix FROM geolocation_unique);

UPDATE geolocation_unique 
SET city = LOWER(TRIM(city));

-- Checking for orphan records

SELECT 'Items with missing Orders' as Issue, COUNT(*) as Count
FROM order_items WHERE order_id NOT IN (SELECT order_id FROM orders)
UNION ALL
SELECT 'Items with missing Products', COUNT(*)
FROM order_items WHERE product_id NOT IN (SELECT product_id FROM products)
UNION ALL
SELECT 'Payments with missing Orders', COUNT(*)
FROM order_payments WHERE order_id NOT IN (SELECT order_id FROM orders);

-- Checking if orders are split across different sellers.

SELECT order_id, COUNT(DISTINCT seller_id) as seller_count
FROM order_items
GROUP BY order_id
HAVING seller_count > 1;

-- Standardizing location since some are in CAPS and others are not.(standardized to small letters.

SELECT LOWER(TRIM(city)), COUNT(*) 
FROM geolocation_unique 
GROUP BY 1 
ORDER BY 2 DESC;

-- finding records whose review time is before the purchase time for discrepency reasons

SELECT COUNT(*) 
FROM order_reviews r
JOIN orders o ON r.order_id = o.order_id
WHERE r.review_creation_date < o.order_purchase_timestamp;



-- Delete rows in 'Child' tables that have no 'Parent' record

DELETE FROM order_items WHERE order_id NOT IN (SELECT order_id FROM orders);
DELETE FROM order_items WHERE product_id NOT IN (SELECT product_id FROM products);
DELETE FROM order_items WHERE seller_id NOT IN (SELECT seller_id FROM sellers);
DELETE FROM order_payments WHERE order_id NOT IN (SELECT order_id FROM orders);
DELETE FROM order_reviews WHERE order_id NOT IN (SELECT order_id FROM orders);

ALTER TABLE product_category_name MODIFY COLUMN product_category_name VARCHAR(255);
ALTER TABLE products MODIFY COLUMN product_category_name VARCHAR(255);

-- Finalize primary key

ALTER TABLE product_category_name DROP PRIMARY KEY, ADD PRIMARY KEY (product_category_name);

-- Adding foreign keys

ALTER TABLE customers ADD CONSTRAINT fk_cust_geo FOREIGN KEY (customer_zip_code_prefix) REFERENCES geolocation_unique(geolocation_zip_code_prefix);
ALTER TABLE sellers ADD CONSTRAINT fk_sell_geo FOREIGN KEY (seller_zip_code_prefix) REFERENCES geolocation_unique(geolocation_zip_code_prefix);
ALTER TABLE orders ADD CONSTRAINT fk_orders_cust FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
ALTER TABLE order_items ADD CONSTRAINT fk_items_orders FOREIGN KEY (order_id) REFERENCES orders(order_id);
ALTER TABLE order_payments ADD CONSTRAINT fk_pay_orders FOREIGN KEY (order_id) REFERENCES orders(order_id);
ALTER TABLE order_reviews ADD CONSTRAINT fk_rev_orders FOREIGN KEY (order_id) REFERENCES orders(order_id);
ALTER TABLE order_items ADD CONSTRAINT fk_items_prod FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE order_items ADD CONSTRAINT fk_items_sell FOREIGN KEY (seller_id) REFERENCES sellers(seller_id);
ALTER TABLE products ADD CONSTRAINT fk_prod_cat FOREIGN KEY (product_category_name) REFERENCES product_category_name(product_category_name);

SET SQL_SAFE_UPDATES = 1



