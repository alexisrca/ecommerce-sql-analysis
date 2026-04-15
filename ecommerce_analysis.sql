-- =============================================
-- E-Commerce Sales Analysis
-- Author: Alexis Ramirez
-- Dataset: UK E-Commerce Transactions (541K rows)
-- Tools: SQL Server (SSMS)
-- =============================================

-- STEP 1: DATA EXPLORATION
--How many null or empty records do we have?
SELECT 
    SUM(CASE WHEN CustomerID IS NULL OR CustomerID = '' THEN 1 ELSE 0 END) AS missing_customers,
    SUM(CASE WHEN Description IS NULL OR Description = '' THEN 1 ELSE 0 END) AS missing_description,
    SUM(CASE WHEN Quantity <= 0 THEN 1 ELSE 0 END) AS negative_quantity,
    SUM(CASE WHEN UnitPrice <= 0 THEN 1 ELSE 0 END) AS zero_price
FROM ecommerce_data;

-- STEP 2: DATA CLEANING
-- Creates clean table getting rid of invalid records.
SELECT *
INTO ecommerce_clean
FROM ecommerce_data
WHERE 
    CustomerID IS NOT NULL AND CustomerID != ''
    AND Description IS NOT NULL AND Description != ''
    AND Quantity > 0
    AND UnitPrice > 0;

-- STEP 3: REVENUE COLUMN
SELECT TOP 5 
    InvoiceNo, 
    Description, 
    Quantity, 
    UnitPrice, 
    ROUND(Quantity * UnitPrice, 2) AS Revenue
FROM ecommerce_clean;

-- STEP 4: SALES BY COUNTRY
SELECT TOP 10
    Country,
    COUNT(DISTINCT InvoiceNo)           AS total_orders,
    SUM(Quantity)                        AS total_units_sold,
    ROUND(SUM(Quantity * UnitPrice), 2)  AS total_revenue
FROM ecommerce_clean
GROUP BY Country
ORDER BY total_revenue DESC;

-- STEP 5: TOP PRODUCTS
SELECT TOP 10
    Description,
    SUM(Quantity)                        AS total_units_sold,
    ROUND(SUM(Quantity * UnitPrice), 2)  AS total_revenue
FROM ecommerce_clean
GROUP BY Description
ORDER BY total_revenue DESC;

-- STEP 6: MONTHLY TREND
WITH monthly_sales AS (
    SELECT 
        LEFT(InvoiceDate, 7)                 AS month,
        ROUND(SUM(Quantity * UnitPrice), 2)  AS monthly_revenue,
        COUNT(DISTINCT InvoiceNo)            AS total_orders
    FROM ecommerce_clean
    GROUP BY LEFT(InvoiceDate, 7)
)
SELECT 
    month,
    total_orders,
    monthly_revenue,
	LAG(monthly_revenue) OVER (ORDER BY month) AS prev_month,
    ROUND(monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY month), 2) AS mom_revenue
FROM monthly_sales
ORDER BY month;

-- STEP 7: TOP CUSTOMERS
SELECT TOP 10
    CustomerID,
    COUNT(DISTINCT InvoiceNo)            AS total_orders,
    SUM(Quantity)                        AS total_units,
    ROUND(SUM(Quantity * UnitPrice), 2)  AS total_spent
FROM ecommerce_clean
GROUP BY CustomerID
ORDER BY total_spent DESC;

-- STEP 8: RFM ANALYSIS
WITH fecha_referencia AS (
    SELECT MAX(CONVERT(DATETIME, InvoiceDate, 101)) AS max_date
    FROM ecommerce_clean
),
rfm AS (
    SELECT
        CustomerID,
        DATEDIFF(
            DAY,
            MAX(CONVERT(DATETIME, InvoiceDate, 101)),
            (SELECT max_date FROM fecha_referencia)
        ) AS recency_days,
        COUNT(DISTINCT InvoiceNo)           AS frequency,
        ROUND(SUM(Quantity * UnitPrice), 2) AS monetary
    FROM ecommerce_clean
    GROUP BY CustomerID
),
rfm_segmented AS (
    SELECT
        CustomerID,
        recency_days,
        frequency,
        monetary,
        -- Individual scoring (1-3 every metric)
        CASE 
            WHEN recency_days <= 30  THEN 3
            WHEN recency_days <= 90  THEN 2
            ELSE 1
        END AS r_score,
        CASE 
            WHEN frequency >= 50 THEN 3
            WHEN frequency >= 20 THEN 2
            ELSE 1
        END AS f_score,
        CASE 
            WHEN monetary >= 10000 THEN 3
            WHEN monetary >= 1000  THEN 2
            ELSE 1
        END AS m_score
    FROM rfm
)
SELECT
    CustomerID,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    r_score + f_score + m_score AS rfm_total,
    -- Segmento final
    CASE
        WHEN r_score = 3 AND f_score = 3 AND m_score = 3 THEN 'Champion'
        WHEN r_score = 3 AND f_score >= 2               THEN 'Loyal Customer'
        WHEN r_score = 3 AND f_score = 1                THEN 'New Customer'
        WHEN r_score = 2 AND f_score >= 2               THEN 'Potential Loyalist'
        WHEN r_score = 1 AND f_score >= 2 AND m_score = 3 THEN 'At Risk - High Value'
        WHEN r_score = 1 AND f_score >= 2               THEN 'At Risk'
        ELSE                                                  'Lost'
    END AS customer_segment
FROM rfm_segmented
ORDER BY rfm_total DESC;

-- STEP 9: RFM SEGMENT SUMMARY
WITH fecha_referencia AS (
    SELECT MAX(CONVERT(DATETIME, InvoiceDate, 101)) AS max_date
    FROM ecommerce_clean
),
rfm AS (
    SELECT
        CustomerID,
        DATEDIFF(
            DAY,
            MAX(CONVERT(DATETIME, InvoiceDate, 101)),
            (SELECT max_date FROM fecha_referencia)
        ) AS recency_days,
        COUNT(DISTINCT InvoiceNo)           AS frequency,
        ROUND(SUM(Quantity * UnitPrice), 2) AS monetary
    FROM ecommerce_clean
    GROUP BY CustomerID
),
rfm_segmented AS (
    SELECT
        CustomerID,
        recency_days,
        frequency,
        monetary,
        CASE 
            WHEN recency_days <= 30  THEN 3
            WHEN recency_days <= 90  THEN 2
            ELSE 1
        END AS r_score,
        CASE 
            WHEN frequency >= 50 THEN 3
            WHEN frequency >= 20 THEN 2
            ELSE 1
        END AS f_score,
        CASE 
            WHEN monetary >= 10000 THEN 3
            WHEN monetary >= 1000  THEN 2
            ELSE 1
        END AS m_score
    FROM rfm
)
-- Executive summary by segment
SELECT
    CASE
        WHEN r_score = 3 AND f_score = 3 AND m_score = 3 THEN 'Champion'
        WHEN r_score = 3 AND f_score >= 2               THEN 'Loyal Customer'
        WHEN r_score = 3 AND f_score = 1                THEN 'New Customer'
        WHEN r_score = 2 AND f_score >= 2               THEN 'Potential Loyalist'
        WHEN r_score = 1 AND f_score >= 2 AND m_score = 3 THEN 'At Risk - High Value'
        WHEN r_score = 1 AND f_score >= 2               THEN 'At Risk'
        ELSE                                                  'Lost'
    END AS customer_segment,
    COUNT(*)                            AS total_customers,
    ROUND(AVG(recency_days), 1)         AS avg_recency_days,
    ROUND(AVG(CAST(frequency AS FLOAT)), 1) AS avg_frequency,
    ROUND(AVG(monetary), 2)             AS avg_monetary,
    ROUND(SUM(monetary), 2)             AS total_revenue_by_segment
FROM rfm_segmented
GROUP BY
    CASE
        WHEN r_score = 3 AND f_score = 3 AND m_score = 3 THEN 'Champion'
        WHEN r_score = 3 AND f_score >= 2               THEN 'Loyal Customer'
        WHEN r_score = 3 AND f_score = 1                THEN 'New Customer'
        WHEN r_score = 2 AND f_score >= 2               THEN 'Potential Loyalist'
        WHEN r_score = 1 AND f_score >= 2 AND m_score = 3 THEN 'At Risk - High Value'
        WHEN r_score = 1 AND f_score >= 2               THEN 'At Risk'
        ELSE                                                  'Lost'
    END
ORDER BY total_revenue_by_segment DESC;