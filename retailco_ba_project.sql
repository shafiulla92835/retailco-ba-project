/* ============================================================
   RETAILCO BUSINESS ANALYST PROJECT
   Database: RetailCo_BA_Project
   Author:   Shafi Ulla Khan
   ============================================================
   SECTION 1: DATA CLEANING
   SECTION 2: EXPLORATORY DATA ANALYSIS (EDA)
   ============================================================ */


/* ============================================================
   SECTION 1 — DATA CLEANING
   ============================================================ */

-- ---------- 1.1 CREATE CLEAN TABLES ----------

-- Clean Customers table
IF OBJECT_ID('ba_customers_clean', 'U') IS NOT NULL
    DROP TABLE ba_customers_clean;
GO
CREATE TABLE ba_customers_clean (
    customer_id     NVARCHAR(50),
    customer_name   NVARCHAR(50),
    Gender          NVARCHAR(50),
    country         NVARCHAR(50),
    segment         NVARCHAR(50),
    Signup_date     DATE
);
GO

-- Clean Orders table
IF OBJECT_ID('ba__orders_clean', 'U') IS NOT NULL
    DROP TABLE ba__orders_clean;
GO
CREATE TABLE ba__orders_clean (
    order_id        NVARCHAR(50),
    customer_id     NVARCHAR(50),
    product_id      NVARCHAR(50),
    quantity        FLOAT,
    channel         NVARCHAR(50),
    order_status    NVARCHAR(50),
    region          NVARCHAR(50),
    order_date      DATE
);
GO

-- Clean Products table
IF OBJECT_ID('ba_products_clean', 'U') IS NOT NULL
    DROP TABLE ba_products_clean;
GO
CREATE TABLE ba_products_clean (
    product_id      NVARCHAR(50),
    product_name    NVARCHAR(50),
    category        NVARCHAR(50),
    unit_cost       FLOAT,
    unit_price      FLOAT
);
GO


-- ---------- 1.2 QUALITY CHECKS ON RAW TABLES ----------

-- Check for duplicate customer_id
SELECT customer_id, COUNT(*) AS dups
FROM ba_project_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Check for duplicate / null product_id
SELECT product_id, COUNT(*) AS dups
FROM ba_project_products
GROUP BY product_id
HAVING COUNT(*) > 1 OR product_id IS NULL;

-- Preview which customer rows will be dropped as duplicates (keeps most recent signup)
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY signup_date DESC) AS flag_last
    FROM ba_project_customers
) t
WHERE flag_last != 1;

-- Preview which order rows will be dropped as duplicates (keeps most recent order_date)
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_date DESC) AS flag_last
    FROM ba_project_orders
) t
WHERE flag_last != 1;

-- Check for unwanted leading/trailing spaces
SELECT segment FROM ba_project_customers WHERE segment != TRIM(segment);
SELECT category FROM ba_project_products WHERE category != TRIM(category);

-- Check value standardization (spot inconsistent casing/spellings before cleaning)
SELECT DISTINCT gender  FROM ba_project_customers;
SELECT DISTINCT segment FROM ba_project_customers;
SELECT DISTINCT category FROM ba_project_products;
SELECT DISTINCT region, LEN(region) FROM ba_project_orders;


-- ---------- 1.3 LOAD CLEANED DATA ----------

-- Customers: dedupe, standardize gender, parse mixed date formats
INSERT INTO ba_customers_clean (customer_id, customer_name, Gender, country, segment, Signup_date)
SELECT
    customer_id,
    customer_name,
    CASE
        WHEN gender IN ('F', 'female', 'Female') THEN 'Female'
        WHEN gender IN ('M', 'Male', 'male')      THEN 'Male'
        ELSE 'Unknown'                              -- NOTE: fixed from 'n\a' typo -> use a real, readable label
    END AS Gender,
    country,
    segment,
    FORMAT(
        CASE
            WHEN signup_date LIKE '____-__-__' THEN TRY_CONVERT(DATE, signup_date, 23)   -- YYYY-MM-DD
            WHEN signup_date LIKE '__/__/____' THEN TRY_CONVERT(DATE, signup_date, 103)  -- DD/MM/YYYY
            WHEN signup_date LIKE '__-__-____' THEN TRY_CONVERT(DATE, signup_date, 110)  -- MM-DD-YYYY
        END,
        'yyyy-MM-dd'
    ) AS Signup_date
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY signup_date DESC) AS flag_last
    FROM ba_project_customers
) t
WHERE flag_last = 1;

-- Orders: dedupe, fill missing quantity, parse mixed date formats
INSERT INTO ba__orders_clean (order_id, customer_id, product_id, quantity, channel, order_status, region, order_date)
SELECT
    order_id,
    customer_id,
    product_id,
    COALESCE(quantity, 0) AS quantity,
    channel,
    order_status,
    region,
    FORMAT(
        CASE
            WHEN order_date LIKE '____-__-__'  THEN TRY_CONVERT(DATE, order_date, 23)                      -- YYYY-MM-DD
            WHEN order_date LIKE '__/__/____'  THEN TRY_CONVERT(DATE, order_date, 103)                     -- DD/MM/YYYY
            WHEN order_date LIKE '__-___-____' THEN TRY_CONVERT(DATE, REPLACE(order_date, '-', ' '), 106)  -- DD-Mon-YYYY
            ELSE NULL
        END,
        'yyyy-MM-dd'
    ) AS order_date
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_date DESC) AS flag_last
    FROM ba_project_orders
) t
WHERE flag_last = 1;

-- Products: cast cost/price to a clean decimal type
INSERT INTO ba_products_clean (product_id, product_name, category, unit_cost, unit_price)
SELECT
    product_id,
    product_name,
    category,
    CAST(unit_cost AS DECIMAL(10,2))  AS unit_cost,
    CAST(unit_price AS DECIMAL(10,2)) AS unit_price
FROM ba_project_products;


/* ============================================================
   SECTION 2 — EXPLORATORY DATA ANALYSIS (EDA)
   ============================================================ */

-- ---------- 2.1 KEY METRICS (single-number summary) ----------

SELECT SUM(c.quantity * p.unit_price) AS total_sales
FROM ba__orders_clean c
LEFT JOIN ba_products_clean p ON c.product_id = p.product_id;

SELECT SUM(quantity) AS total_items_sold
FROM ba__orders_clean;

SELECT AVG(unit_price) AS avg_price
FROM ba_products_clean;

SELECT AVG(unit_cost) AS avg_cost
FROM ba_products_clean;

SELECT COUNT(DISTINCT order_id) AS total_orders
FROM ba__orders_clean;

SELECT COUNT(DISTINCT product_id) AS total_products
FROM ba_products_clean;

SELECT COUNT(customer_id) AS total_customers
FROM ba_customers_clean;

SELECT COUNT(DISTINCT customer_id) AS customers_who_ordered
FROM ba__orders_clean;


-- ---------- 2.2 KEY METRICS REPORT (all-in-one, for dashboard/README) ----------

SELECT 'total_revenue' AS measure_name,
       SUM(c.quantity * p.unit_price) AS measure_value
FROM ba__orders_clean c
LEFT JOIN ba_products_clean p ON c.product_id = p.product_id
UNION ALL
SELECT 'total_items_sold', SUM(quantity)
FROM ba__orders_clean
UNION ALL
SELECT 'avg_price', CAST(AVG(unit_price) AS DECIMAL(10,2))
FROM ba_products_clean
UNION ALL
SELECT 'avg_cost', CAST(AVG(unit_cost) AS DECIMAL(10,2))
FROM ba_products_clean
UNION ALL
SELECT 'total_orders', COUNT(DISTINCT order_id)
FROM ba__orders_clean
UNION ALL
SELECT 'total_customers', COUNT(customer_id)
FROM ba_customers_clean;


-- ---------- 2.3 DIMENSIONS BREAKDOWN ----------

-- Order volume by region
SELECT region, COUNT(*) AS order_count
FROM ba__orders_clean
GROUP BY region
ORDER BY order_count DESC;

-- Order status breakdown (% share)
SELECT order_status,
       COUNT(*) AS cnt,
       CONCAT(CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)), '%') AS pct
FROM ba__orders_clean
GROUP BY order_status;

-- Orders by channel
SELECT channel, COUNT(*) AS order_count
FROM ba__orders_clean
GROUP BY channel
ORDER BY order_count DESC;

-- Revenue by category (completed orders only)
SELECT p.category,
       SUM(c.quantity * p.unit_price) AS total_revenue
FROM ba__orders_clean c
LEFT JOIN ba_products_clean p ON p.product_id = c.product_id
WHERE c.order_status = 'Completed'
GROUP BY p.category
ORDER BY total_revenue DESC;

-- Customer segment split
SELECT segment, COUNT(*) AS customers_count
FROM ba_customers_clean
GROUP BY segment;


-- ---------- 2.4 PROFITABILITY ----------

-- Gross profit & gross margin (COGS-based; excludes overhead/marketing/shipping)
SELECT
    SUM(c.quantity * p.unit_price) AS total_revenue,
    SUM(c.quantity * p.unit_cost)  AS total_cogs,
    SUM(c.quantity * p.unit_price) - SUM(c.quantity * p.unit_cost) AS gross_profit,
    CAST((SUM(c.quantity * p.unit_price) - SUM(c.quantity * p.unit_cost)) * 100.0
         / SUM(c.quantity * p.unit_price) AS DECIMAL(5,2)) AS gross_margin_pct
FROM ba__orders_clean c
LEFT JOIN ba_products_clean p ON p.product_id = c.product_id;


-- ---------- 2.5 MAGNITUDE ANALYSIS ----------

-- Revenue by country
SELECT c.country, SUM(o.quantity * p.unit_price) AS total_revenue
FROM ba__orders_clean o
LEFT JOIN ba_products_clean p  ON o.product_id  = p.product_id
LEFT JOIN ba_customers_clean c ON o.customer_id = c.customer_id
GROUP BY c.country
ORDER BY total_revenue DESC;

-- Quantity sold by category
SELECT p.category, SUM(o.quantity) AS total_quantity
FROM ba__orders_clean o
LEFT JOIN ba_products_clean p ON o.product_id = p.product_id
GROUP BY p.category
ORDER BY total_quantity DESC;

-- Average price by product
SELECT product_name, AVG(unit_price) AS avg_price
FROM ba_products_clean
GROUP BY product_name
ORDER BY avg_price DESC;

-- Customers by country
SELECT country, COUNT(customer_id) AS total_customers
FROM ba_customers_clean
GROUP BY country
ORDER BY total_customers DESC;

-- Customers by gender
SELECT Gender, COUNT(customer_id) AS total_customers
FROM ba_customers_clean
GROUP BY Gender
ORDER BY total_customers DESC;

-- Products by category
SELECT category, COUNT(product_name) AS total_products
FROM ba_products_clean
GROUP BY category
ORDER BY total_products DESC;

-- Average cost by category
SELECT category, AVG(unit_cost) AS avg_cost
FROM ba_products_clean
GROUP BY category
ORDER BY avg_cost DESC;

-- Total revenue by category (completed orders only)
SELECT p.category,
       CAST(SUM(o.quantity * p.unit_price) AS DECIMAL(10,2)) AS total_revenue
FROM ba__orders_clean o
LEFT JOIN ba_products_clean p ON o.product_id = p.product_id
WHERE o.order_status = 'Completed'
GROUP BY p.category
ORDER BY total_revenue DESC;

-- Revenue by customer
SELECT c.customer_id, c.customer_name,
       SUM(o.quantity * p.unit_price) AS total_revenue
FROM ba__orders_clean o
LEFT JOIN ba_products_clean p  ON o.product_id  = p.product_id
LEFT JOIN ba_customers_clean c ON o.customer_id = c.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_id, c.customer_name
ORDER BY total_revenue DESC;

-- Distribution of sold items across countries
SELECT c.country, SUM(o.quantity) AS sold_items
FROM ba__orders_clean o
LEFT JOIN ba_customers_clean c ON o.customer_id = c.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.country
ORDER BY sold_items DESC;


-- ---------- 2.6 RANKING ANALYSIS ----------

-- Top 5 products by revenue
SELECT *
FROM (
    SELECT p.product_name,
           CAST(SUM(o.quantity * p.unit_price) AS DECIMAL(10,2)) AS total_revenue,
           ROW_NUMBER() OVER (ORDER BY SUM(o.quantity * p.unit_price) DESC) AS rank_products
    FROM ba__orders_clean o
    LEFT JOIN ba_products_clean p ON o.product_id = p.product_id
    WHERE o.order_status = 'Completed'
    GROUP BY p.product_name
) t
WHERE rank_products <= 5;

-- Bottom 5 products by revenue
SELECT TOP 5 p.product_name,
       CAST(SUM(o.quantity * p.unit_price) AS DECIMAL(10,2)) AS total_revenue
FROM ba__orders_clean o
LEFT JOIN ba_products_clean p ON o.product_id = p.product_id
WHERE o.order_status = 'Completed'
GROUP BY p.product_name
ORDER BY total_revenue ASC;

-- Top 10 customers by revenue
SELECT TOP 10 c.customer_id, c.customer_name,
       CAST(SUM(o.quantity * p.unit_price) AS DECIMAL(10,2)) AS total_revenue
FROM ba__orders_clean o
LEFT JOIN ba_products_clean p  ON o.product_id  = p.product_id
LEFT JOIN ba_customers_clean c ON o.customer_id = c.customer_id
WHERE o.order_status = 'Completed'
GROUP BY c.customer_id, c.customer_name
ORDER BY total_revenue DESC;

-- 3 customers with fewest orders
SELECT TOP 3 c.customer_id, c.customer_name,
       COUNT(o.order_id) AS total_orders
FROM ba__orders_clean o
LEFT JOIN ba_customers_clean c ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_orders ASC;
