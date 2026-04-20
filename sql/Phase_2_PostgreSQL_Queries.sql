-- ============================================================
-- OLIST eCOMMERCE STORE PERFORMANCE AUDIT
-- Phase 2 — PostgreSQL Queries
-- Uses cleaned_data/ from Phase 1
-- Author: Smit Bhavsar
-- ============================================================

-- ============================================================
-- STEP 1: CREATE ALL 4 TABLES IN POSTGRESQL
-- (All 4 come from cleaned_data/ — NOT from raw data/)
-- ============================================================
-- Here is what each cleaned file is and why we need it:
--
--  olist_master.csv      → ALL orders with every column pre-joined
--                          and pre-calculated (delivery delay, revenue,
--                          English category, year/month/hour etc.)
--
--  olist_delivered.csv   → Same as master but ONLY delivered orders.
--                          Used for all revenue and RFM queries.
--
--  olist_products_clean.csv → Products table with English category
--                          name already added. Needed for product-level
--                          details like photos_qty, weight, dimensions.
--                          Note: product_category is ALREADY in master
--                          so most queries don't need this separately —
--                          only queries that need weight/photos/size do.
--
--  olist_sellers_clean.csv → Sellers with city and state.
--                          Needed when you want to analyse WHERE sellers
--                          are located and join to order performance.
--                          seller_id is in order_items (raw) but NOT
--                          in master — so use this for seller queries.
-- ============================================================


-- TABLE 1: All orders (delivered + cancelled + others)
CREATE TABLE IF NOT EXISTS olist_master (
    order_id                        VARCHAR(50),
    customer_id                     VARCHAR(50),
    order_status                    VARCHAR(20),
    order_purchase_timestamp        TIMESTAMP,
    order_approved_at               TIMESTAMP,
    order_delivered_carrier_date    TIMESTAMP,
    order_delivered_customer_date   TIMESTAMP,
    order_estimated_delivery_date   TIMESTAMP,
    order_year                      INTEGER,
    order_month                     INTEGER,
    order_month_name                VARCHAR(20),
    order_day_of_week               VARCHAR(15),
    order_hour                      INTEGER,
    delivery_delay_days             FLOAT,
    actual_delivery_days            FLOAT,
    is_late                         BOOLEAN,
    customer_unique_id              VARCHAR(50),
    customer_city                   VARCHAR(100),
    customer_state                  CHAR(2),
    total_items                     NUMERIC,
    total_price                     FLOAT,
    total_freight                   FLOAT,
    total_revenue                   FLOAT,
    product_category                VARCHAR(100),
    payment_type                    VARCHAR(30),
    payment_installments            NUMERIC,
    payment_value                   FLOAT,
    review_score                    FLOAT
);

ALTER TABLE olist_master
ALTER COLUMN total_items TYPE NUMERIC;

ALTER TABLE olist_master
ALTER COLUMN payment_installments TYPE NUMERIC;


-- TABLE 2: Delivered orders only (same columns as master)
CREATE TABLE IF NOT EXISTS olist_delivered (
    LIKE olist_master INCLUDING ALL
);

ALTER TABLE olist_delivered
ALTER COLUMN total_items TYPE NUMERIC;

ALTER TABLE olist_delivered
ALTER COLUMN payment_installments TYPE NUMERIC;


-- TABLE 3: Products with English category name
-- Use this when you need: product photos, weight, dimensions
-- product_category (English) is already in master/delivered
-- so only join this table when you need product-specific columns
CREATE TABLE IF NOT EXISTS olist_products_clean (
    product_id                      VARCHAR(50) PRIMARY KEY,
    product_category_name           VARCHAR(100),   -- Portuguese
    product_name_lenght             INTEGER,
    product_description_lenght      INTEGER,
    product_photos_qty              INTEGER,        -- useful for analysis
    product_weight_g                FLOAT,          -- affects freight cost
    product_length_cm               FLOAT,
    product_height_cm               FLOAT,
    product_width_cm                FLOAT,
    product_category_name_english   VARCHAR(100)    -- English (added by Phase 1)
);

ALTER TABLE olist_products_clean
ALTER COLUMN product_name_lenght TYPE NUMERIC;

ALTER TABLE olist_products_clean
ALTER COLUMN product_description_lenght TYPE NUMERIC;

ALTER TABLE olist_products_clean
ALTER COLUMN product_photos_qty TYPE NUMERIC;


-- TABLE 4: Sellers with location info
-- Use this when you need: which city/state a seller is in
-- seller_id exists in raw order_items but NOT in olist_master
-- so load raw order_items too if you need seller-level revenue
CREATE TABLE IF NOT EXISTS olist_sellers_clean (
    seller_id                       VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix          VARCHAR(10),
    seller_city                     VARCHAR(100),
    seller_state                    CHAR(2)
);

-- ============================================================
-- STEP 2: IMPORT CSV FILES IN pgAdmin (ALL 4 FILES)
-- ============================================================
-- For EACH table below, do this in pgAdmin:
--   Right-click the table name → Import/Export Data → Import
--   Set Header = YES, Delimiter = comma
--
--   TABLE             → CSV FILE TO IMPORT
--   olist_master      → cleaned_data/olist_master.csv
--   olist_delivered   → cleaned_data/olist_delivered.csv
--   olist_products_clean → cleaned_data/olist_products_clean.csv
--   olist_sellers_clean  → cleaned_data/olist_sellers_clean.csv
-- ============================================================

-- ============================================================
-- STEP 3: VERIFY ALL 4 TABLES LOADED CORRECTLY
-- Run this block after importing all 4 CSV files
-- ============================================================


-- Check olist_delivered (most important)
SELECT
    'olist_delivered'                       AS table_name,
    COUNT(*)                                AS total_rows,
    COUNT(DISTINCT order_id)                AS unique_orders,
    COUNT(DISTINCT customer_unique_id)      AS unique_customers,
    ROUND(SUM(total_revenue)::NUMERIC, 2)   AS total_revenue
FROM olist_delivered

-- Check olist_master
SELECT
    'olist_master' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(DISTINCT customer_unique_id) AS unique_customers,
    ROUND(SUM(total_revenue)::NUMERIC, 2) AS total_revenue
FROM olist_master

-- Check olist_products_clean
SELECT
    'olist_products_clean' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_id) AS Total_product_id,
    COUNT(DISTINCT product_category_name_english) AS product_category_name_english
FROM olist_products_clean

-- Check olist_sellers_clean
SELECT
    'olist_sellers_clean' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT seller_id) AS Total_seller_id,
    COUNT(DISTINCT seller_state) AS Total_seller_status
FROM olist_sellers_clean;

-- ============================================================
-- QUERY 1: Total Revenue & Month-over-Month Growth
-- Business Question: How has revenue grown each month?
-- Columns used: order_year, order_month, order_month_name,
--               total_revenue (all pre-built in Phase 1)
-- ============================================================
WITH monthly AS (
    SELECT
        order_year,
        order_month,
        order_month_name,
        COUNT(DISTINCT order_id)              AS total_orders,
        ROUND(SUM(total_revenue)::NUMERIC, 2) AS monthly_revenue,
        ROUND(AVG(total_revenue)::NUMERIC, 2) AS avg_order_value
    FROM olist_delivered
    WHERE order_year IN (2017, 2018)
    GROUP BY order_year, order_month, order_month_name
),
lagged AS (
    SELECT *,
           LAG(monthly_revenue) OVER (
               ORDER BY order_year, order_month
           ) AS prev_month_revenue
    FROM monthly
)
SELECT
    order_year,
    order_month,
    order_month_name,
    total_orders,
    monthly_revenue,
    avg_order_value,
    prev_month_revenue,
    ROUND(
        (monthly_revenue - prev_month_revenue) 
        / NULLIF(prev_month_revenue, 0) * 100
    , 1) AS mom_growth_pct
FROM lagged
ORDER BY order_year, order_month;

-- ============================================================
-- QUERY 2: Top Product Categories by Revenue
-- Business Question: Which categories drive 80% of revenue?
-- Columns used: product_category, total_revenue, review_score
-- (product_category is already in English from Phase 1)
-- ============================================================
SELECT
    product_category,
    COUNT(DISTINCT order_id)                            AS total_orders,
    ROUND(SUM(total_revenue)::NUMERIC, 2)               AS revenue,
    ROUND(AVG(total_revenue)::NUMERIC, 2)               AS avg_order_value,
    ROUND(AVG(review_score)::NUMERIC, 2)                AS avg_review_score,
    ROUND(
        (SUM(total_revenue) * 100.0
        / SUM(SUM(total_revenue)) OVER ())::NUMERIC
    , 2)                                                AS revenue_share_pct
FROM olist_delivered
WHERE product_category IS NOT NULL
GROUP BY product_category
ORDER BY revenue DESC
LIMIT 15;


-- ============================================================
-- QUERY 3: Customer Repeat Purchase Analysis
-- Business Question: What % of customers buy more than once?
-- Columns used: customer_unique_id, order_id, total_revenue
-- ============================================================

WITH customer_summary AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id)                        AS order_count,
        ROUND(SUM(total_revenue)::NUMERIC, 2)           AS total_spent,
        ROUND(AVG(total_revenue)::NUMERIC, 2)           AS avg_order_value
    FROM olist_delivered
    GROUP BY customer_unique_id
)
SELECT
    CASE
        WHEN order_count = 1  THEN '1 order  — New customer'
        WHEN order_count = 2  THEN '2 orders — Returning'
        WHEN order_count = 3  THEN '3 orders — Regular'
        WHEN order_count >= 4 THEN '4+ orders — Loyal'
    END                                                 AS customer_segment,
    COUNT(*)                                            AS customer_count,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()
    , 2)                                                AS pct_of_customers,
    ROUND(SUM(total_spent)::NUMERIC, 2)                 AS segment_revenue,
    ROUND(AVG(avg_order_value)::NUMERIC, 2)             AS avg_order_value
FROM customer_summary
GROUP BY customer_segment
ORDER BY MIN(order_count);

-- ============================================================
-- QUERY 4: Delivery Performance by State
-- Business Question: Which states have worst delays?
-- Columns used: customer_state, delivery_delay_days,
--               actual_delivery_days, is_late, review_score
-- (all pre-calculated in Phase 1 — no date math needed!)
-- ============================================================

SELECT
    customer_state,
    COUNT(DISTINCT order_id)                        AS total_orders,
    ROUND(AVG(actual_delivery_days)::NUMERIC, 1)    AS avg_delivery_days,
    ROUND(AVG(delivery_delay_days)::NUMERIC, 1)     AS avg_delay_days,
    ROUND(
        SUM(CASE WHEN is_late = TRUE THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*)::NUMERIC
    , 1)                                            AS late_delivery_pct,
    ROUND(AVG(review_score)::NUMERIC, 2)            AS avg_review_score
FROM olist_delivered
GROUP BY customer_state
HAVING COUNT(DISTINCT order_id) > 100
ORDER BY avg_delay_days DESC
LIMIT 15;

-- ============================================================
-- QUERY 5: Review Score vs Delivery Delay
-- Business Question: Does late delivery cause bad reviews?
-- Columns used: review_score, delivery_delay_days, is_late
-- ============================================================

SELECT
    review_score::INTEGER                               AS review_score,
    COUNT(*)                                            AS total_orders,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()
    , 1)                                                AS pct_of_orders,
    ROUND(AVG(delivery_delay_days)::NUMERIC, 1)         AS avg_delay_days,
    ROUND(AVG(actual_delivery_days)::NUMERIC, 1)        AS avg_actual_delivery_days,
    ROUND(
        SUM(CASE WHEN is_late = TRUE THEN 1 ELSE 0 END)
        * 100.0 / COUNT(*)
    , 1)                                                AS pct_delivered_late
FROM olist_delivered
WHERE review_score IS NOT NULL
GROUP BY review_score::INTEGER
ORDER BY review_score;

-- ============================================================
-- QUERY 6: Payment Method Analysis
-- Business Question: Which payment method is most popular?
-- Columns used: payment_type, payment_installments,
--               total_revenue, review_score
-- ============================================================

SELECT
    payment_type,
    COUNT(DISTINCT order_id)                            AS total_orders,
    ROUND(
        COUNT(DISTINCT order_id) * 100.0
        / SUM(COUNT(DISTINCT order_id)) OVER ()
    ::NUMERIC, 1)                                       AS pct_of_orders,
    ROUND(AVG(total_revenue)::NUMERIC, 2)               AS avg_order_value,
    ROUND(SUM(total_revenue)::NUMERIC, 2)               AS total_revenue,
    ROUND(AVG(payment_installments)::NUMERIC, 1)        AS avg_installments,
    ROUND(AVG(review_score)::NUMERIC, 2)                AS avg_review_score
FROM olist_delivered
WHERE payment_type IS NOT NULL
  AND payment_type != 'not_defined'
  AND payment_type != 'unknown'
GROUP BY payment_type
ORDER BY total_orders DESC;

-- ============================================================
-- QUERY 7: Order Cancellation Rate by Category
-- Business Question: Which categories lose most orders?
-- Uses olist_master (not delivered) to see ALL statuses
-- ============================================================

SELECT
    product_category,
    COUNT(DISTINCT order_id)                        AS total_orders,
    COUNT(DISTINCT order_id) FILTER (
        WHERE order_status = 'canceled'
    )                                               AS cancelled_orders,
    ROUND(
        COUNT(DISTINCT order_id) FILTER (
            WHERE order_status = 'canceled'
        ) * 100.0 / COUNT(DISTINCT order_id)
    ::NUMERIC, 2)                                   AS cancellation_rate_pct
FROM olist_master
WHERE product_category IS NOT NULL
GROUP BY product_category
HAVING COUNT(DISTINCT order_id) > 50
ORDER BY cancellation_rate_pct DESC;

-- ============================================================
-- QUERY 8A: Seller Performance by State
-- Business Question: Which states have the best sellers?
-- Tables used: olist_sellers_clean + raw order_items
-- WHY olist_sellers_clean: it has seller_city and seller_state
--   which are NOT in olist_master. We join it to raw order_items
--   to get revenue per seller.
-- ============================================================

-- NOTE: For this query you need to also import the RAW
-- order_items CSV into PostgreSQL because seller_id is only
-- in that file. Create and import it like this first:

CREATE TABLE IF NOT EXISTS olist_order_items_raw (
    order_id            VARCHAR(50),
    order_item_id       INTEGER,
    product_id          VARCHAR(50),
    seller_id           VARCHAR(50),
    shipping_limit_date TIMESTAMP,
    price               FLOAT,
    freight_value       FLOAT
);

-- Import: data/olist_order_items_dataset.csv (raw data folder)

WITH seller_revenue AS (
    SELECT
        oi.seller_id,
        COUNT(DISTINCT oi.order_id)       AS total_orders,
        ROUND(SUM(oi.price)::NUMERIC, 2)        AS total_revenue,
        ROUND(AVG(oi.price)::NUMERIC, 2)        AS avg_item_price
    FROM olist_order_items_raw oi
    JOIN olist_master om 
        ON oi.order_id = om.order_id
    WHERE om.order_status = 'delivered'
    GROUP BY oi.seller_id
),
seller_with_location AS (
    SELECT
        sr.seller_id,
        sc.seller_city,
        sc.seller_state,
        sr.total_orders,
        sr.total_revenue,
        sr.avg_item_price,
        RANK() OVER (ORDER BY sr.total_revenue DESC) AS revenue_rank,
        ROUND(
    (PERCENT_RANK() OVER (ORDER BY sr.total_revenue DESC))::NUMERIC * 100,
    1
) AS revenue_percentile
    FROM seller_revenue sr
    JOIN olist_sellers_clean sc 
        ON sr.seller_id = sc.seller_id
)
SELECT
    seller_state,
    COUNT(DISTINCT seller_id)               AS seller_count,
    ROUND(SUM(total_revenue)::NUMERIC, 2)   AS state_total_revenue,
    ROUND(AVG(total_revenue)::NUMERIC, 2)   AS avg_revenue_per_seller,
    ROUND(AVG(avg_item_price)::NUMERIC, 2)  AS avg_item_price,
    SUM(total_orders)                       AS total_orders_fulfilled
FROM seller_with_location
GROUP BY seller_state
ORDER BY state_total_revenue DESC;

-- ============================================================
-- QUERY 8B: Top 10 Individual Sellers
-- Business Question: Who are the highest revenue sellers?
-- Tables used: olist_sellers_clean + olist_order_items_raw
-- ============================================================

SELECT
        oi.seller_id,
        COUNT(DISTINCT oi.order_id)             AS total_orders,
        ROUND(SUM(oi.price)::NUMERIC, 2)        AS total_revenue,
        ROUND(AVG(oi.price)::NUMERIC, 2)        AS avg_item_price,
        PERCENT_RANK() OVER (
            ORDER BY SUM(oi.price)
        )                                       AS revenue_percentile
    FROM olist_order_items_raw oi
    JOIN olist_master om ON oi.order_id = om.order_id
    WHERE om.order_status = 'delivered'
    GROUP BY oi.seller_id

-- ============================================================
-- QUERY 8C: Product Photos vs Review Score
-- Business Question: Do products with more photos get
--                    better reviews?
-- Tables used: olist_products_clean + olist_delivered
-- WHY olist_products_clean: it has product_photos_qty and
--   product_weight_g which are NOT in olist_master
-- ============================================================

SELECT
    CASE
        WHEN pc.product_photos_qty = 1   THEN '1 photo'
        WHEN pc.product_photos_qty <= 3  THEN '2-3 photos'
        WHEN pc.product_photos_qty <= 5  THEN '4-5 photos'
        WHEN pc.product_photos_qty <= 10 THEN '6-10 photos'
        ELSE '10+ photos'
    END                                         AS photo_bucket,
    COUNT(DISTINCT pc.product_id)               AS product_count,
    COUNT(oi.order_id)                          AS total_orders,
    ROUND(AVG(od.review_score)::NUMERIC, 2)     AS avg_review_score,
    ROUND(AVG(od.total_revenue)::NUMERIC, 2)    AS avg_order_value,
    ROUND(AVG(pc.product_weight_g)::NUMERIC, 0) AS avg_weight_g
FROM olist_products_clean pc
JOIN olist_order_items_raw oi ON pc.product_id  = oi.product_id
JOIN olist_delivered od        ON oi.order_id   = od.order_id
WHERE od.review_score IS NOT NULL
GROUP BY photo_bucket
ORDER BY MIN(pc.product_photos_qty);

-- ============================================================
-- QUERY 9: Peak Shopping Hours & Days
-- Business Question: When do customers shop most?
-- Columns used: order_day_of_week, order_hour
-- (pre-extracted in Phase 1 — no EXTRACT needed!)
-- ============================================================

-- By day of week
SELECT
    order_day_of_week,
    COUNT(DISTINCT order_id)                            AS total_orders,
    ROUND(AVG(total_revenue)::NUMERIC, 2)               AS avg_order_value,
    ROUND(SUM(total_revenue)::NUMERIC, 2)               AS total_revenue
FROM olist_delivered
GROUP BY order_day_of_week
ORDER BY total_orders DESC;

-- By hour of day
SELECT
    order_hour,
    COUNT(DISTINCT order_id)                            AS total_orders,
    ROUND(AVG(total_revenue)::NUMERIC, 2)               AS avg_order_value
FROM olist_delivered
GROUP BY order_hour
ORDER BY order_hour;

-- ============================================================
-- QUERY 10: Geographic Revenue Analysis
-- Business Question: Which states drive most revenue?
-- Columns used: customer_state, total_revenue,
--               actual_delivery_days, review_score
-- ============================================================

SELECT
    customer_state,
    COUNT(DISTINCT order_id)                            AS total_orders,
    COUNT(DISTINCT customer_unique_id)                  AS unique_customers,
    ROUND(SUM(total_revenue)::NUMERIC, 2)               AS total_revenue,
    ROUND(AVG(total_revenue)::NUMERIC, 2)               AS avg_order_value,
    ROUND(AVG(review_score)::NUMERIC, 2)                AS avg_review_score,
    ROUND(AVG(actual_delivery_days)::NUMERIC, 1)        AS avg_delivery_days,
    -- Revenue rank across all states
    RANK() OVER (
        ORDER BY SUM(total_revenue) DESC
    )                                                   AS revenue_rank
FROM olist_delivered
GROUP BY customer_state
ORDER BY total_revenue DESC;

-- ============================================================
-- QUERY 11: Freight-to-Price Ratio (Margin Risk)
-- Business Question: Which categories have shipping eating margins?
-- Columns used: product_category, total_price, total_freight
-- ============================================================

SELECT
    product_category,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(AVG(total_price)::NUMERIC, 2)                 AS avg_product_price,
    ROUND(AVG(total_freight)::NUMERIC, 2)               AS avg_freight_cost,
    ROUND(
        (AVG(total_freight) * 100.0 / NULLIF(AVG(total_price), 0))::NUMERIC,
        1
    ) AS freight_to_price_pct,
    ROUND(AVG(review_score)::NUMERIC, 2)                AS avg_review_score
FROM olist_delivered
WHERE product_category IS NOT NULL
  AND total_price > 0
GROUP BY product_category
HAVING COUNT(DISTINCT order_id) > 50
ORDER BY freight_to_price_pct DESC;

-- ============================================================
-- QUERY 12: Black Friday & Seasonal Spikes
-- Business Question: What are the biggest single sales days?
-- Columns used: order_purchase_timestamp, order_year
-- ============================================================

-- Top revenue days in 2017
SELECT
    DATE(order_purchase_timestamp)                      AS order_date,
    COUNT(DISTINCT order_id)                            AS total_orders,
    ROUND(SUM(total_revenue)::NUMERIC, 2)               AS daily_revenue,
    ROUND(AVG(total_revenue)::NUMERIC, 2)               AS avg_order_value
FROM olist_delivered
WHERE order_year = 2017
GROUP BY DATE(order_purchase_timestamp)
ORDER BY daily_revenue DESC
LIMIT 10;
-- Look for Nov 24 2017 = Black Friday spike!

-- Monthly seasonality comparison
SELECT
    order_month,
    order_year,
    COUNT(DISTINCT order_id)                            AS total_orders,
    ROUND(SUM(total_revenue)::NUMERIC, 2)               AS monthly_revenue
FROM olist_delivered
WHERE order_year IN (2017, 2018)
GROUP BY order_month, order_year
ORDER BY order_year, order_month;

-- ============================================================
-- BONUS: RFM Segmentation in PostgreSQL
-- Business Question: How do we segment all customers?
-- Columns used: customer_unique_id, order_purchase_timestamp,
--               total_revenue, order_id
-- ============================================================

WITH customer_metrics AS (
    SELECT
        customer_unique_id,
        -- Days since last purchase (snapshot = day after last order)
        DATE '2018-10-18' - MAX(DATE(order_purchase_timestamp)) AS recency_days,
        COUNT(DISTINCT order_id)                        AS frequency,
        ROUND(SUM(total_revenue)::NUMERIC, 2)           AS monetary
    FROM olist_delivered
    GROUP BY customer_unique_id
),
rfm_scored AS (
    SELECT
        customer_unique_id,
        recency_days,
        frequency,
        monetary,
        -- Lower recency = more recent = score 5
        NTILE(5) OVER (ORDER BY recency_days DESC)      AS r_score,
        -- Higher frequency = score 5
        NTILE(5) OVER (ORDER BY frequency ASC)          AS f_score,
        -- Higher monetary = score 5
        NTILE(5) OVER (ORDER BY monetary ASC)           AS m_score
    FROM customer_metrics
)
SELECT
    customer_unique_id,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    r_score + f_score + m_score                         AS rfm_total,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4
            THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3
            THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 2
            THEN 'Recent Customers'
        WHEN r_score >= 3 AND m_score >= 3
            THEN 'Potential Loyalists'
        WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3
            THEN 'At-Risk Customers'
        WHEN r_score <= 2 AND f_score >= 2
            THEN 'Cannot Lose Them'
        WHEN r_score = 1 AND f_score = 1
            THEN 'Lost Customers'
        WHEN r_score + f_score + m_score >= 9
            THEN 'Promising'
        ELSE
            'Needs Attention'
    END                                                 AS rfm_segment
FROM rfm_scored
ORDER BY rfm_total DESC;
