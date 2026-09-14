DROP TABLE IF EXISTS transactions_clean;

CREATE TABLE transactions_clean AS
SELECT
    invoice,
    stock_code,
    description,
    quantity,
    invoice_date,
    price,
    customer_id,
    country,
    quantity * price AS line_revenue   -- revenue per line, used everywhere downstream
FROM transactions_raw
WHERE invoice NOT LIKE 'C%'            -- remove cancellations
  AND customer_id IS NOT NULL         -- can't analyse customers we can't identify
  AND quantity > 0                    -- drop returns/adjustments with non-positive qty
  AND price > 0                       -- drop zero/negative priced lines (freebies, errors)
  AND stock_code NOT IN ('POST','DOT','M','BANK CHARGES','AMAZONFEE','C2','S')
                                      -- common non-product codes: postage, fees, manual, etc.
  AND stock_code NOT REGEXP '^(ADJUST|gift)';  -- adjustments & gift-card lines
  
  SELECT
    COUNT(*) AS rows_kept,
    COUNT(DISTINCT customer_id) AS customers,
    COUNT(DISTINCT invoice) AS orders,
    MIN(invoice_date) AS first_date,
    MAX(invoice_date) AS last_date,
    ROUND(SUM(line_revenue), 2) AS total_revenue
FROM transactions_clean;

DROP TABLE IF EXISTS customer_summary;

CREATE TABLE customer_summary AS
SELECT
    customer_id,
    MIN(invoice_date) AS first_purchase,
    MAX(invoice_date) AS last_purchase,
    DATEDIFF(
        (SELECT DATE_ADD(MAX(invoice_date), INTERVAL 1 DAY) FROM transactions_clean),
        MAX(invoice_date)
    ) AS recency_days,                       -- days since last purchase (R)
    COUNT(DISTINCT invoice) AS frequency,    -- number of orders (F)
    ROUND(SUM(line_revenue), 2) AS monetary, -- total spend (M)
    ROUND(AVG(line_revenue), 2) AS avg_line_value,
    COUNT(DISTINCT stock_code) AS distinct_products,
    DATEDIFF(MAX(invoice_date), MIN(invoice_date)) AS tenure_days
FROM transactions_clean
GROUP BY customer_id;

SELECT COUNT(*) AS num_customers FROM customer_summary;
SELECT * FROM customer_summary ORDER BY monetary DESC LIMIT 10;  -- your top spenders

SELECT VERSION();
USE retail;

DROP TABLE IF EXISTS rfm_scores;

CREATE TABLE rfm_scores AS
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    -- Recency: DESC order so the MOST recent buyers (lowest days) land in bucket 5
    NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
    -- Frequency: more orders = higher score
    NTILE(5) OVER (ORDER BY frequency ASC)     AS f_score,
    -- Monetary: more spend = higher score
    NTILE(5) OVER (ORDER BY monetary ASC)      AS m_score
FROM customer_summary;

DROP TABLE IF EXISTS customer_segments;

CREATE TABLE customer_segments AS
SELECT
    customer_id,
    recency_days, frequency, monetary,
    r_score, f_score, m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_cell,
    CASE
        WHEN r_score >= 4 AND f_score >= 4              THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 3              THEN 'Loyal'
        WHEN r_score >= 4 AND f_score <= 2              THEN 'New / Promising'
        WHEN r_score = 3  AND f_score <= 2              THEN 'Potential Loyalist'
        WHEN r_score = 2  AND f_score >= 3              THEN 'At Risk'
        WHEN r_score <= 2 AND f_score >= 4              THEN 'Cant Lose Them'
        WHEN r_score <= 2 AND f_score = 2              THEN 'Hibernating'
        WHEN r_score = 1                                THEN 'Lost'
        ELSE 'Others'
    END AS segment
FROM rfm_scores;
-- segment sizes and their value — your headline table

SELECT
    segment,
    COUNT(*) AS customers,
    ROUND(AVG(recency_days), 0) AS avg_recency,
    ROUND(AVG(frequency), 1) AS avg_frequency,
    ROUND(SUM(monetary), 2) AS total_value,
    ROUND(100 * SUM(monetary) / (SELECT SUM(monetary) FROM customer_segments), 1) AS pct_of_revenue
FROM customer_segments
GROUP BY segment
ORDER BY total_value DESC;

USE retail;

-- How long do customers typically go between the dataset's end and their last buy?
SELECT
    ROUND(AVG(recency_days), 0) AS avg_recency,
    MIN(recency_days) AS min_recency,
    MAX(recency_days) AS max_recency
FROM customer_summary;

-- The distribution matters more than the average — see where customers cluster
SELECT
    CASE
        WHEN recency_days <= 30  THEN '0-30 days'
        WHEN recency_days <= 90  THEN '31-90 days'
        WHEN recency_days <= 180 THEN '91-180 days'
        WHEN recency_days <= 365 THEN '181-365 days'
        ELSE '365+ days'
    END AS recency_band,
    COUNT(*) AS customers
FROM customer_summary
GROUP BY recency_band
ORDER BY MIN(recency_days);

DROP TABLE IF EXISTS customer_churn;

CREATE TABLE customer_churn AS
SELECT
    cs.*,
    CASE WHEN cs.recency_days > 90 THEN 1 ELSE 0 END AS churned
FROM customer_summary cs;

SELECT
    churned,
    COUNT(*) AS customers,
    ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM customer_churn), 1) AS pct
FROM customer_churn
GROUP BY churned;