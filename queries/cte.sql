
-- Q1. Top 10 customers by revenue, and each one's share of total sales
WITH customer_sales AS (
    SELECT
        c.customer_id,
        c.customer_name,
        c.segment,
        SUM(oi.sales) AS revenue
    FROM order_items AS oi
    JOIN orders      AS o ON o.order_id    = oi.order_id
    JOIN customers   AS c ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name, c.segment
),
total AS (
    SELECT SUM(revenue) AS total_revenue
    FROM customer_sales
)
SELECT
    cs.customer_name,
    cs.segment,
    ROUND(cs.revenue, 2)                            AS revenue,
    ROUND(100.0 * cs.revenue / t.total_revenue, 2)  AS pct_of_total_sales
FROM customer_sales AS cs
CROSS JOIN total AS t
ORDER BY cs.revenue DESC
LIMIT 10;

-- Q2. Do bigger discounts hurt profit?
WITH banded AS (
    SELECT
        CASE
            WHEN discount = 0    THEN '1) no discount'
            WHEN discount <= 0.2 THEN '2) 1-20%'
            WHEN discount <= 0.4 THEN '3) 21-40%'
            ELSE                      '4) over 40%'
        END AS discount_band,
        sales,
        profit
    FROM order_items
)
SELECT
    discount_band,
    COUNT(*)                                         AS order_lines,
    ROUND(SUM(sales), 2)                             AS revenue,
    ROUND(SUM(profit), 2)                            AS profit,
    ROUND(100.0 * SUM(profit) / SUM(sales), 1)       AS profit_margin_pct
FROM banded
GROUP BY discount_band
ORDER BY discount_band;

-- Q3. Do the loss-making sub-categories get bigger discounts?
WITH subcat AS (
    SELECT
        p.sub_category,
        ROUND(SUM(oi.sales), 2)                      AS revenue,
        ROUND(100.0 * SUM(oi.profit) / SUM(oi.sales), 1) AS profit_margin_pct,
        ROUND(100.0 * AVG(oi.discount), 1)           AS avg_discount_pct
    FROM order_items AS oi
    JOIN products    AS p ON p.product_id = oi.product_id
    GROUP BY p.sub_category
)
SELECT *
FROM subcat
ORDER BY profit_margin_pct ASC
LIMIT 6;