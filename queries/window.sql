-- Q1. Monthly revenue with a running total that restarts each year
WITH monthly AS (
    SELECT
        substr(o.order_date, 1, 4) AS year,
        substr(o.order_date, 1, 7) AS month,
        SUM(oi.sales)              AS revenue
    FROM order_items AS oi
    JOIN orders      AS o ON o.order_id = oi.order_id
    GROUP BY substr(o.order_date, 1, 7)
)
SELECT
    month,
    ROUND(revenue, 2) AS revenue,
    ROUND(SUM(revenue) OVER (
              PARTITION BY year
              ORDER BY month
          ), 2)        AS running_total_in_year
FROM monthly
ORDER BY month;

-- Q2. Top 3 products by revenue within each category
WITH product_sales AS (
    SELECT
        p.category,
        p.product_name,
        SUM(oi.sales) AS revenue
    FROM order_items AS oi
    JOIN products    AS p ON p.product_id = oi.product_id
    GROUP BY p.category, p.product_id, p.product_name
),
ranked AS (
    SELECT
        category,
        product_name,
        ROUND(revenue, 2) AS revenue,
        RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rank_in_category
    FROM product_sales
)
SELECT *
FROM ranked
WHERE rank_in_category <= 3
ORDER BY category, rank_in_category;

-- Q3. YoY revenue growth using LAG()
WITH yearly AS (
    SELECT
        substr(o.order_date, 1, 4) AS year,
        SUM(oi.sales)              AS revenue
    FROM order_items AS oi
    JOIN orders      AS o ON o.order_id = oi.order_id
    GROUP BY substr(o.order_date, 1, 4)
)
SELECT
    year,
    ROUND(revenue, 2)                                   AS revenue,
    ROUND(LAG(revenue) OVER (ORDER BY year), 2)         AS previous_year_revenue,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY year))
                / LAG(revenue) OVER (ORDER BY year), 1) AS yoy_growth_pct
FROM yearly
ORDER BY year;