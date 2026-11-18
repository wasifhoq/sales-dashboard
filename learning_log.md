# Learning Log

---

## 2026-11-13
- Set up project structure with `data/`, `schema/`, `queries/`, and `dashboard/` folders, along with Git and `.gitignore`.
- Converted raw `superstore_sample.csv` (cp1252 encoding) into clean UTF-8 `superstore_clean.csv` using Python.
- Designed ERD and normalized data into 4 relational tables: `customers`, `products`, `orders`, and `order_items`.
- Created `schema/create_tables.sql` with primary and foreign key constraints, plus a temporary `stg_superstore` staging table.
- Wrote `schema/load_data.sql` to import the CSV, transform date fields into `YYYY-MM-DD` format, populate all 4 tables, and clean up staging.
- Successfully built `sales.db` with 793 customers, 1,862 products, 5,009 orders, and 9,994 order items.

## 2026-11-14
- Created `queries/cte.sql` to analyze customer revenue concentration and discount sensitivity using Common Table Expressions.
- Identified the top 10 customers by revenue and calculated their individual share of total sales (Sean Miller leads at $25,043, or 1.09%).
- Grouped order items into 4 discount bands (none, 1-20%, 21-40%, >40%) to evaluate impact on profitability.
- Discovered that profit margins plunge into severe negative territory once discounts exceed 20% (-15.3% margin for 21-40%, and -77.4% margin for >40%).
- Confirmed that heavy discounting is the root cause of losses in sub-categories like Tables (26.1% avg discount, -8.6% margin) and Bookcases (21.1% avg discount, -3.0% margin).

## 2026-11-18
- Authored `queries/window.sql` covering running totals with `SUM() OVER`, product rankings with `RANK() OVER`, and YoY growth using `LAG()`.
- Built the dashboard pipeline in R (`dashboard/generate_charts.R`) connecting directly to `sales.db` via `DBI` and `RSQLite`.
- Generated 5 core analytical charts with `ggplot2` visualizing monthly trends, discount sensitivity, subcategory profits, customer segments, and annual growth.
- Applied conditional styling in subcategory analysis to clearly highlight loss-making categories (Tables, Bookcases, Supplies) in red.
- Packaged the visualization suite into a clean Bootstrap 5 dashboard (`dashboard/index.html`) displaying high-level retail KPIs and charts.
