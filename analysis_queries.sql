SELECT VERSION();
CREATE DATABASE olist;
USE olist;
SHOW TABLES;
SELECT * FROM orders LIMIT 7;

SELECT SUM(price) AS total_revenue
FROM order_items;

SELECT 
    DATE_FORMAT(o.order_purchase_timestamp,'%Y-%m') AS month,
    SUM(oi.price) AS revenue
FROM orders o
JOIN order_items oi
	ON o.order_id=oi.order_id
GROUP BY month
ORDER BY month;

SELECT 
	DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS month,
    COUNT(DISTINCT o.order_id) AS num_orders,
    SUM(oi.price) AS revenue,
    ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id),2) AS revenue_per_order
FROM orders o
JOIN order_items oi
	ON o.order_id = oi.order_id
GROUP BY month
ORDER BY month;

SELECT
	DATE_FORMAT(o.order_purchase_timestamp,' %Y-%m ') AS month,
	COUNT(DISTINCT o.order_id) AS num_orders,
    SUM(oi.price) AS revenue
FROM orders o 
JOIN order_items oi
	ON o.order_id = oi.order_id
WHERE o.order_purchase_timestamp >= '2017-01-01'
	AND o.order_purchase_timestamp < '2018-09-01'
GROUP BY month
ORDER BY month;

SELECT
    t.product_category_name_english AS category,
    COUNT(DISTINCT oi.order_id) AS num_orders,
    SUM(oi.price) AS revenue
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
GROUP BY category
ORDER BY revenue DESC
LIMIT 15;

WITH customer_orders AS(
	SELECT 
		c.customer_unique_id,
        COUNT(o.order_id) OVER (PARTITION BY c.customer_unique_id) AS total_orders
        FROM orders o
        JOIN customers c
			ON o.customer_id= c.customer_id
)

SELECT 
	 CASE 
		WHEN total_orders =1 THEN 'one-time'
        ELSE 'repeat'
	END AS customer_type,
    COUNT(*) AS num_rows
FROM customer_orders
GROUP BY customer_type;


WITH CUSTOMER_ORDERS AS(
	SELECT 
		c.customer_unique_id,
        COUNT(o.order_id) OVER (PARTITION BY c.customer_unique_id) AS total_orders
	FROM orders o
    JOIN customers c
		ON o.customer_id = c.customer_id
),
labelled AS (
	SELECT DISTINCT 
		customer_unique_id,
        CASE WHEN total_orders =1 THEN 'one-time' ELSE 'repeat' END AS customer_type
	FROM customer_orders
)
SELECT 
	COUNT(*) AS total_customers,
    SUM(CASE WHEN customer_type = 'repeat' THEN 1 ELSE 0 END) AS repeat_customers,
    ROUND(
		100.0*SUM(CASE WHEN customer_type = 'repeat' THEN 1 ELSE 0 END)/ COUNT(*),
        2
        )
        AS repeat_rate_pct
        FROM labelled;
        
WITH customer_stats AS(
	SELECT 
		c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS last_order_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.price) AS monetary
	FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
),
rfm AS (
	SELECT 
		customer_unique_id,
		DATEDIFF('2018-09-01',last_order_date) AS recency_days,
		frequency,
		monetary,
		NTILE(5) OVER(ORDER BY DATEDIFF('2018-09-01',last_order_date) DESC) AS r_score,
		NTILE(5) OVER(ORDER BY frequency ASC) AS f_score,
		NTILE(5) OVER(ORDER BY monetary ASC) AS m_score
	FROM customer_stats
)
SELECT *
FROM rfm
ORDER BY r_score DESC,f_score DESC,m_score DESC
LIMIT 100;


CREATE TABLE rfm_segments AS
WITH customer_stats AS(
	SELECT 
		c.customer_unique_id,
        MAX(o.order_purchase_timestamp) AS last_order_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.price) AS monetary
	FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY c.customer_unique_id
),
rfm AS(
	SELECT
		customer_unique_id,
        NTILE(5) OVER(ORDER BY DATEDIFF('2018-09-01',last_order_date) DESC) AS r_score,
		NTILE(5) OVER(ORDER BY frequency ASC) AS f_score,
		NTILE(5) OVER(ORDER BY monetary ASC) AS m_score
		FROM customer_stats
),
segments AS(
	SELECT
		customer_unique_id,
        r_score,f_score,m_score,
        CASE 
			WHEN r_score >= 4 AND f_score >=4 THEN 'Champions'
			WHEN r_score >= 4 AND f_score >=2 THEN 'Loyal'
			WHEN r_score >= 4 THEN 'New Customers'
			WHEN r_score >= 2 AND f_score >=3 THEN 'At-risk'
            ELSE 'Lost'
		END AS segment
	FROM rfm
)
SELECT * FROM segments;

SELECT 
    segment,
    COUNT(*) AS num_customers,
    ROUND(100.0 * COUNT(*)/ SUM(COUNT(*)) OVER (),2) AS pct_of_base
FROM rfm_segments
GROUP BY segment
ORDER BY num_customers DESC;

USE olist;

CREATE INDEX idx_items_order   ON order_items(order_id);
CREATE INDEX idx_items_product ON order_items(product_id);
CREATE INDEX idx_orders_order  ON orders(order_id);
CREATE INDEX idx_products_prod ON products(product_id);
CREATE INDEX idx_products_cat  ON products(product_category_name(100));
CREATE INDEX idx_trans_cat     ON product_category_name_translation(product_category_name);



            
