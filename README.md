# SQL Sales Database & Analytics Dashboard

A normalized SQLite database built from a flat retail sales CSV, with SQL queries (joins, CTEs, window functions) and an R dashboard that answer business questions about revenue, profit, and discount sensitivity.

## Problem

The source data is a single flat file of 9,994 rows, where customer, product, order and shipping details repeat on every line. That makes it hard to query reliably and easy to introduce inconsistencies. The goal is to:

1. Restructure the file into a normalized relational schema.
2. Load and validate the data.
3. Use SQL to answer questions a retail business would ask: which customers, products and regions drive revenue, and where profit is being lost.
4. Visualize key findings in an analytical performance dashboard.

## Data

- **Source:** Superstore Dataset (Kaggle), https://www.kaggle.com/datasets/vivek468/superstore-dataset-final
- **Size:** 9,994 order lines, 21 columns, orders placed from 2014-01-03 to 2017-12-30
- **Note:** This is a public, fictional retail dataset, not data from a real business of mine. I chose it because it has the structure needed to practice schema design and analytical SQL.

## Method

### Schema

The flat file was split into four tables. I checked how the columns depend on each other before designing it:

- Each customer ID has exactly one name and one segment, so these go in `customers`.
- Each product ID has exactly one category and sub-category, so these go in `products`.
- Each order has exactly one customer, date, ship mode and ship-to location, so these go in `orders`.
- Customers ship to many different postal codes (780 of 793 customers have more than one), so location belongs to the **order**, not the customer.
- Eight order lines repeat the same order and product, so `(order_id, product_id)` is not unique. The CSV's `Row ID` is the primary key of `order_items`.

```
customers    (customer_id PK, customer_name, segment)
products     (product_id PK, product_name, category, sub_category)
orders       (order_id PK, customer_id FK, order_date, ship_date, ship_mode,
              country, region, state, city, postal_code)
order_items  (order_item_id PK, order_id FK, product_id FK,
              sales, quantity, discount, profit)
```

The ERD is in [`schema/ERD.png`](schema/ERD.png).

### Data cleaning

| Issue | How it was handled |
|---|---|
| CSV is Windows-1252 encoded, not UTF-8 | `data/prepare_data.py` converts it to UTF-8 |
| Non-breaking spaces in product names | Replaced with normal spaces |
| Dates are `M/D/YYYY` text | Converted to `YYYY-MM-DD` so they sort correctly |
| Postal codes lost leading zeros (`01841` became `1841`) | Stored as text and padded to 5 digits |
| 32 product IDs appear with more than one spelling of the name | Kept one name per ID (the alphabetically first) |

### Validation

After loading, the row counts match the expected values, the total sales figure matches the CSV exactly, and `PRAGMA foreign_key_check` returns no errors.

| Table | Rows |
|---|---|
| customers | 793 |
| products | 1,862 |
| orders | 5,009 |
| order_items | 9,994 |

Total sales: $2,297,200.86. Total profit: $286,397.02 (overall margin about 12.5%).

## Results and Analysis

### 1. Revenue and Margin by Customer Segment

| Segment | Revenue | Profit margin |
|---|---|---|
| Consumer | $1,161,401 | 11.5% |
| Corporate | $706,146 | 13.0% |
| Home Office | $429,653 | 14.0% |

Consumer accounts bring in the largest revenue volume, but Home Office generates the highest profit margin.

### 2. Top Customers and Revenue Concentration (CTE)

From [`queries/cte.sql`](queries/cte.sql), using CTEs to rank customers and compute their share of total revenue:

- Top customer: Sean Miller ($25,043.05, 1.09% of total sales).
- The top 10 customers collectively account for approximately 6.7% of total revenue.
- Revenue is well diversified across accounts with minimal customer concentration risk.

### 3. Impact of Discounts on Profitability (CTE)

Grouping orders into discount tiers revealed that aggressive discounts are the primary cause of margin collapse:

| Discount Band | Order Lines | Revenue | Profit | Profit Margin |
|---|---|---|---|---|
| No discount (0%) | 4,798 | $1,087,908.47 | +$320,987.60 | **+29.5%** |
| 1–20% | 3,803 | $846,522.24 | +$100,785.47 | **+11.9%** |
| 21–40% | 460 | $234,137.90 | -$35,817.47 | **-15.3%** |
| Over 40% | 933 | $128,632.25 | -$99,558.59 | **-77.4%** |

Discounts up to 20% stay profitable. Once discounts exceed 20%, sales turn sharply negative, with orders discounted over 40% losing 77.4 cents on every dollar sold.

### 4. Loss-Making Sub-Categories vs. Discounts

Cross-checking sub-category profitability against average discount rates confirmed the root cause:

- **Tables:** -$17,725.48 profit (-8.6% margin), average discount 26.1%
- **Bookcases:** -$3,472.56 profit (-3.0% margin), average discount 21.1%
- **Supplies:** -$1,189.10 profit (-2.5% margin), average discount 7.7%

Tables and Bookcases operate at high sales volume ($321k+ combined) but lose money because their average discount rates fall well inside the loss-making >20% discount zone.

### 5. Running Totals, Product Rankings, and YoY Growth (Window Functions)

From [`queries/window.sql`](queries/window.sql):
- **Running Monthly Totals:** Used `SUM() OVER (PARTITION BY year ORDER BY month)` to track cumulative annual progress, highlighting consistent Q4 holiday sales surges.
- **Top Products by Category:** Used `RANK() OVER (PARTITION BY category ORDER BY revenue DESC)` to isolate top revenue contributors per category.
- **Year-over-Year Growth:** Evaluated yearly progress with `LAG()`:
  - 2014: $484,247.50 (Baseline)
  - 2015: $470,532.51 (-2.8% YoY)
  - 2016: $609,205.60 (+29.5% YoY)
  - 2017: $733,215.26 (+20.4% YoY)

## Dashboard

The analysis was compiled into an R Markdown dashboard ([`dashboard/dashboard.md`](dashboard/dashboard.md) and [`dashboard/dashboard.Rmd`](dashboard/dashboard.Rmd)) querying `sales.db` directly and visualizing trends with `ggplot2`:

1. **Monthly Revenue and Profit Over Time:** [`dashboard/figure/chart1_monthly-1.png`](dashboard/figure/chart1_monthly-1.png) — shows recurring Q4 sales peaks and margin consistency across all 48 months.
2. **Profit Margin by Discount Level:** [`dashboard/figure/chart2_discount-1.png`](dashboard/figure/chart2_discount-1.png) — visualizes the margin drop when discounts pass 20%.
3. **Total Profit by Sub-Category:** [`dashboard/figure/chart3_subcategory-1.png`](dashboard/figure/chart3_subcategory-1.png) — horizontal bar chart highlighting Tables, Bookcases, and Supplies in red.
4. **Revenue by Customer Segment:** [`dashboard/figure/chart4_segment-1.png`](dashboard/figure/chart4_segment-1.png) — segment sales labelled with respective profit margin percentages.
5. **Annual Revenue & YoY Growth:** [`dashboard/figure/chart5_yearly-1.png`](dashboard/figure/chart5_yearly-1.png) — annual revenue bars annotated with growth rates computed via SQL `LAG()`.

## Business Recommendations

1. **Cap promotional discounts at 20%:** Discounts above 20% caused over $135k in cumulative losses across 1,393 transactions. Establishing a hard approval threshold at 20% will protect gross margin.
2. **Re-evaluate pricing and discount rules for Tables and Bookcases:** These two lines generate substantial volume but suffer from high average discounts (21%–26%). Restricting promotions on Tables alone would eliminate $17.7k in net losses.
3. **Grow high-margin B2B accounts:** Home Office (14.0% margin) and Corporate (13.0% margin) produce higher margins than Consumer. Increasing sales efforts in these segments improves overall portfolio margin.
4. **Plan capacity for Q4 demand peaks:** Time-series trends show sharp demand acceleration in October–December every year; inventory and fulfillment capacity should be pre-allocated ahead of Q4.

## Project Structure

```
.
├── README.md
├── learning_log.md
├── sales.db
├── data/
│   ├── superstore_sample.csv     (raw download from Kaggle)
│   ├── superstore_clean.csv      (UTF-8 version, created by prepare_data.py)
│   └── prepare_data.py
├── schema/
│   ├── create_tables.sql
│   ├── load_data.sql
│   ├── create.sql
│   ├── ERD.png
│   └── Erd.svg
├── queries/
│   ├── cte.sql
│   └── window.sql
└── dashboard/
    ├── dashboard.Rmd
    ├── dashboard.md
    ├── generate_charts.R
    └── figure/
        ├── chart1_monthly-1.png
        ├── chart2_discount-1.png
        ├── chart3_subcategory-1.png
        ├── chart4_segment-1.png
        └── chart5_yearly-1.png
```

## How to Reproduce

You need Python 3, the SQLite command-line tool (version 3.25 or later, for window functions), and optionally R with `ggplot2`, `DBI`, `RSQLite`, and `rmarkdown` to run the dashboard.

1. Download the CSV from the Kaggle link above and save it as `data/superstore_sample.csv`.
2. From the project root, convert the file to UTF-8:
   ```bash
   python data/prepare_data.py
   ```
3. Create the database and load the data:
   ```bash
   sqlite3 sales.db ".read schema/create_tables.sql" ".read schema/load_data.sql"
   ```
4. Run any query file:
   ```bash
   sqlite3 -header -column sales.db ".read queries/cte.sql"
   sqlite3 -header -column sales.db ".read queries/window.sql"
   ```
5. Generate the dashboard charts or render the report:
   ```bash
   Rscript dashboard/generate_charts.R
   R -e "rmarkdown::render('dashboard/dashboard.Rmd', output_format = 'github_document')"
   ```

## Tools

SQLite, DBeaver, Python, R (`ggplot2`, `rmarkdown`), dbdiagram.io (ERD), Git.

## Learning Log

See [`learning_log.md`](learning_log.md) for dated notes on what I learned and what I would improve.
