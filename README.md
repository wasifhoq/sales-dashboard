# SQL Sales Database

A normalized SQLite database built from a flat retail sales CSV, with SQL queries (joins, CTEs, window functions) that answer business questions about revenue and profit.

**Status:** In progress. The schema, ERD, data load, and CTE queries are done. Window-function queries and the dashboard are up next (see [Roadmap](#roadmap)).

## Problem

The source data is a single flat file of 9,994 rows, where customer, product, order and shipping details repeat on every line. That makes it hard to query reliably and easy to introduce inconsistencies. The goal is to:

1. Restructure the file into a normalized relational schema.
2. Load and validate the data.
3. Use SQL to answer questions a retail business would ask: which customers, products and regions drive revenue, and where profit is being lost.

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

Total sales: 2,297,200.86. Total profit: 286,397.02 (overall margin about 12.5%).

## Results so far

### 1. From CTE Queries ([`queries/cte.sql`](queries/cte.sql))

**Top 10 customers by revenue and share of total sales:**

| Customer Name | Segment | Revenue | % of Total Sales |
|---|---|---|---|
| Sean Miller | Home Office | $25,043.05 | 1.09% |
| Tamara Chand | Corporate | $19,052.22 | 0.83% |
| Raymond Buch | Consumer | $15,117.34 | 0.66% |
| Tom Ashbrook | Home Office | $14,595.62 | 0.64% |
| Adrian Barton | Consumer | $14,473.57 | 0.63% |
| Ken Lonsdale | Consumer | $14,175.23 | 0.62% |
| Sanjit Chand | Consumer | $14,142.33 | 0.62% |
| Hunter Lopez | Consumer | $12,873.30 | 0.56% |
| Sanjit Engle | Consumer | $12,209.44 | 0.53% |
| Christopher Conant | Consumer | $12,129.07 | 0.53% |

*Revenue is well-diversified: even the single largest customer accounts for just over 1% of total sales.*

**Do bigger discounts hurt profit? (Discount Sensitivity):**

| Discount Band | Order Lines | Revenue | Profit | Profit Margin |
|---|---|---|---|---|
| 1) No discount | 4,798 | $1,087,908.47 | $320,987.60 | **+29.5%** |
| 2) 1–20% | 3,803 | $846,522.24 | $100,785.47 | **+11.9%** |
| 3) 21–40% | 460 | $234,137.90 | -$35,817.47 | **-15.3%** |
| 4) Over 40% | 933 | $128,632.25 | -$99,558.59 | **-77.4%** |

*Discounts up to 20% remain healthy. Once discounts exceed 20%, every additional dollar sold loses money; discounts over 40% result in a devastating -77.4% margin.*

**Loss-making sub-categories vs. average discounts:**

| Sub-Category | Revenue | Profit Margin | Avg Discount |
|---|---|---|---|
| Tables | $206,965.53 | -8.6% | 26.1% |
| Bookcases | $114,880.00 | -3.0% | 21.1% |
| Supplies | $46,673.54 | -2.5% | 7.7% |
| Machines | $189,238.63 | +1.8% | 30.6% |
| Chairs | $328,449.10 | +8.1% | 17.0% |
| Storage | $223,843.61 | +9.5% | 7.5% |

*The loss-making sub-categories (Tables and Bookcases) receive unusually high average discounts (21%–26%), putting them right into the negative margin threshold identified above.*

### 2. Segment & Geographic Overview

**Revenue and margin by customer segment:**

| Segment | Revenue | Profit margin |
|---|---|---|
| Consumer | $1,161,401 | 11.5% |
| Corporate | $706,146 | 13.0% |
| Home Office | $429,653 | 14.0% |

Consumer brings in the most revenue, but Home Office has the highest margin.

**Top states by revenue:** California (~$457,688), New York (~$310,876) and Texas (~$170,188). Average time from order to shipping is about 4 days in each of the top five states.

## Business recommendations

1. **Cap promotional discounts at 20%:** The data shows clear proof that discounting beyond 20% destroys profitability (-$135k lost across bands 3 & 4). 
2. **Re-evaluate pricing on Tables and Bookcases:** These two sub-categories generate over $320k in revenue but operate at a combined loss due to heavy average discounting (21%–26%). Capping discounts or eliminating promotions on Tables would immediately turn them profitable.
3. **Protect Home Office & Corporate accounts:** While Consumer represents the bulk of volume, Home Office delivers the highest profit margin (14.0%) and includes top enterprise buyers like Sean Miller.

## Limitations

- The data is a public, fictional dataset, so the findings illustrate the method rather than describe a real business.
- Product names were reduced to one per product ID, so any analysis at the product-name level depends on that choice.
- Differences in margin between segments and sub-categories are descriptive. I have not tested whether they are statistically meaningful.
- The recommendation above is a hypothesis to test, not a conclusion.

## Roadmap

- [x] Normalized schema and ERD
- [x] Data cleaning and load, with validation
- [x] Join queries
- [x] CTE queries (top customers & share of sales, discount sensitivity bands, sub-category discount analysis)
- [x] Check whether discounts explain the loss-making sub-categories (confirmed: avg discounts >20% cause negative margins)
- [ ] Window-function queries (running monthly totals, product rank within category, year-over-year growth with `LAG()`)
- [ ] Dashboard in Tableau or R

## Project structure

```
.
├── README.md
├── learning_log.md
├── data/
│   ├── superstore_sample.csv     (raw download from Kaggle)
│   ├── superstore_clean.csv      (UTF-8 version, created by prepare_data.py)
│   └── prepare_data.py
├── schema/
│   ├── create_tables.sql
│   ├── load_data.sql
│   └── ERD.png
├── queries/
│   └── cte.sql
└── dashboard/
```

## How to reproduce

You need Python 3 and the SQLite command-line tool (version 3.25 or later, for window functions).

1. Download the CSV from the Kaggle link above and save it as `data/superstore_sample.csv`.
2. From the project root, convert the file to UTF-8:
   ```
   python data/prepare_data.py
   ```
3. Create the database and load the data:
   ```
   sqlite3 sales.db ".read schema/create_tables.sql" ".read schema/load_data.sql"
   ```
4. Run any query file, for example:
   ```
   sqlite3 -header -column sales.db ".read queries/cte.sql"
   ```

## Tools

SQLite, DBeaver, Python, dbdiagram.io (ERD), Git.

## Learning log

See [`learning_log.md`](learning_log.md) for dated notes on what I learned and what I would improve.
