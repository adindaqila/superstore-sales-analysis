-- Superstore sales analysis (MySQL, phpMyAdmin)
-- Kaggle Superstore, public dataset, not company data


-- 1. Raw table
-- Import all columns as text, then convert dates and numbers below
-- CSV imported with the phpMyAdmin Import tab (utf-8)
CREATE TABLE orders_raw (
  row_id VARCHAR(20),
  order_id VARCHAR(30),
  order_date VARCHAR(20),
  ship_date VARCHAR(20),
  ship_mode VARCHAR(30),
  customer_id VARCHAR(20),
  customer_name VARCHAR(100),
  segment VARCHAR(30),
  country VARCHAR(50),
  city VARCHAR(100),
  state VARCHAR(100),
  postal_code VARCHAR(20),
  region VARCHAR(30),
  product_id VARCHAR(30),
  category VARCHAR(50),
  sub_category VARCHAR(50),
  product_name VARCHAR(255),
  sales VARCHAR(30),
  quantity VARCHAR(10),
  discount VARCHAR(10),
  profit VARCHAR(30)
) CHARACTER SET utf8mb4;


-- 2. Data checks
-- 9994 rows, all columns varchar
SELECT COUNT(*) AS total_rows FROM orders_raw;
SELECT * FROM orders_raw LIMIT 5;
DESCRIBE orders_raw;

-- sales and profit have at most 4 decimals, so DECIMAL(12,4) is enough
SELECT MAX(LENGTH(SUBSTRING_INDEX(sales, '.', -1))) AS max_decimals_sales,
       MAX(LENGTH(SUBSTRING_INDEX(profit, '.', -1))) AS max_decimals_profit
FROM orders_raw;

SELECT order_date, STR_TO_DATE(order_date, '%m/%d/%Y') AS new_date
FROM orders_raw LIMIT 5;


-- 3. Clean table
-- text -> DATE and DECIMAL so sorting, SUM and grouping by month work
CREATE TABLE orders_clean AS
SELECT
  CAST(row_id AS UNSIGNED) AS row_id,
  TRIM(order_id) AS order_id,
  STR_TO_DATE(order_date, '%m/%d/%Y') AS order_date,
  STR_TO_DATE(ship_date, '%m/%d/%Y') AS ship_date,
  TRIM(ship_mode) AS ship_mode,
  TRIM(customer_id) AS customer_id,
  TRIM(customer_name) AS customer_name,
  TRIM(segment) AS segment,
  TRIM(country) AS country,
  TRIM(city) AS city,
  TRIM(state) AS state,
  TRIM(postal_code) AS postal_code,
  TRIM(region) AS region,
  TRIM(product_id) AS product_id,
  TRIM(category) AS category,
  TRIM(sub_category) AS sub_category,
  TRIM(product_name) AS product_name,
  CAST(sales AS DECIMAL(12,4)) AS sales,
  CAST(quantity AS UNSIGNED) AS quantity,
  CAST(discount AS DECIMAL(5,2)) AS discount,
  CAST(profit AS DECIMAL(12,4)) AS profit
FROM orders_raw;

-- 9994 rows, 0 failed dates
SELECT COUNT(*) FROM orders_clean;
SELECT COUNT(*) FROM orders_clean WHERE order_date IS NULL OR ship_date IS NULL;
DESCRIBE orders_clean;


-- 4. Duplicate check
-- one row = one product in one order, so order_id + product_id should be unique
-- Found 8 repeated order-product pairs.
-- Kept all rows, including one identical pair (row_id 3406 and 3407): impact <0.02% of sales.
SELECT order_id, product_id, COUNT(*) AS row_count
FROM orders_clean
GROUP BY order_id, product_id
HAVING COUNT(*) > 1;

SELECT o.row_id, o.order_id, o.product_id, o.sales,
       o.quantity, o.discount, o.profit
FROM orders_clean o
JOIN (
  SELECT order_id, product_id
  FROM orders_clean
  GROUP BY order_id, product_id
  HAVING COUNT(*) > 1
) d ON o.order_id = d.order_id AND o.product_id = d.product_id
ORDER BY o.order_id, o.product_id, o.row_id;


-- 5. Analysis

-- 5.1 Totals (matches the dashboard)
-- sales 2,297,200.86 / profit 286,397.02 / margin 12.47%
SELECT ROUND(SUM(sales),2) AS total_sales,
       ROUND(SUM(profit),2) AS total_profit
FROM orders_clean;

-- 5.2 Lowest margin months
-- profit didn't always follow sales in the trend chart, so I checked margin
-- 2015-01 is the worst (-18.05%); 2016-11 has high sales but only 5.05% margin
SELECT DATE_FORMAT(order_date, '%Y-%m') AS order_month,
       ROUND(SUM(sales), 2) AS total_sales,
       ROUND(SUM(profit), 2) AS total_profit,
       ROUND(SUM(profit) * 100 / SUM(sales), 2) AS margin_pct
FROM orders_clean
GROUP BY order_month
ORDER BY margin_pct ASC
LIMIT 5;

-- 5.3 What lost money in January 2015
-- Tables had the largest loss among sub-categories in January 2015.
-- check average discounts for the other loss-making sub-categories.
SELECT sub_category,
       ROUND(SUM(sales),2) AS total_sales,
       ROUND(SUM(profit),2) AS total_profit,
       ROUND(AVG(discount)*100,1) AS avg_discount_pct
FROM orders_clean
WHERE DATE_FORMAT(order_date, '%Y-%m') = '2015-01'
GROUP BY sub_category
ORDER BY total_profit ASC
LIMIT 5;

-- 5.4 Profit by discount band (whole dataset, not just one month)
-- 0%: +320,988 | 1-20%: +100,785 | 21-40%: -35,817 | >40%: -99,559
-- bands are my own choice, not a standard
SELECT CASE WHEN discount = 0 THEN '0%'
            WHEN discount <= 0.2 THEN '1-20%'
            WHEN discount <= 0.4 THEN '21-40%'
            ELSE '>40%' END AS discount_band,
       COUNT(*) AS row_count,
       ROUND(SUM(sales),2) AS total_sales,
       ROUND(SUM(profit),2) AS total_profit
FROM orders_clean
GROUP BY discount_band
ORDER BY MIN(discount);

-- 5.5 Loss-making sub-categories vs Copiers (most profitable)
-- Tables, Bookcases, Supplies lose money
-- Supplies was loss-making despite a relatively low average discount.
-- the dataset does not include enough cost detail to explain why.
SELECT sub_category,
       ROUND(SUM(sales),2) AS total_sales,
       ROUND(SUM(profit),2) AS total_profit,
       ROUND(AVG(discount)*100,1) AS avg_discount_pct
FROM orders_clean
WHERE sub_category IN ('Tables','Bookcases','Supplies','Copiers')
GROUP BY sub_category
ORDER BY total_profit;

-- 5.6 Discount by region
-- Central: highest avg discount (24.0%), lowest margin (7.9%)
-- West: lowest discount (10.9%), highest margin (14.9%)
SELECT region,
       ROUND(SUM(sales),2) AS total_sales,
       ROUND(SUM(profit),2) AS total_profit,
       ROUND(AVG(discount)*100,1) AS avg_discount_pct
FROM orders_clean
GROUP BY region
ORDER BY avg_discount_pct DESC;


-- 6. Queries exported to CSV for the Looker Studio dashboard

-- monthly_sales_profit.csv (48 rows)
SELECT
    DATE_FORMAT(order_date, '%Y-%m') AS order_month,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM orders_clean
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY order_month;

-- product_performance.csv (17 rows)
SELECT
    category,
    sub_category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM orders_clean
GROUP BY category, sub_category
ORDER BY total_sales DESC;

-- regional_performance.csv (4 rows)
SELECT
    region,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM orders_clean
GROUP BY region
ORDER BY total_sales DESC;

-- customer_segment.csv (3 rows)
SELECT
    segment,
    COUNT(DISTINCT customer_id) AS total_customers,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM orders_clean
GROUP BY segment
ORDER BY total_sales DESC;

-- discount_impact.csv (4 rows) = query 5.4