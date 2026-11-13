# SQL Sales Database

A normalized SQLite database built from a flat retail sales CSV, with SQL queries (joins, CTEs, window functions) that answer business questions about revenue and profit.

**Status:** In progress. The schema, ERD, data load and join queries are done. CTE queries, window-function queries and the dashboard are still to come (see [Roadmap](#roadmap)).

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

From the join queries in [`queries/01_joins.sql`](queries/01_joins.sql):

**Revenue and margin by customer segment**

| Segment | Revenue | Profit margin |
|---|---|---|
| Consumer | 1,161,401 | 11.5% |
| Corporate | 706,146 | 13.0% |
| Home Office | 429,653 | 14.0% |

Consumer brings in the most revenue, but Home Office has the highest margin.

**Loss-making sub-categories**

- Tables: -8.6% margin (about -17,725 profit on about 206,966 revenue)
- Bookcases: -3.0% margin
- Supplies: -2.5% margin

All other sub-categories are profitable.

**Top states by revenue:** California (about 457,688), New York (about 310,876) and Texas (about 170,188). Average time from order to shipping is about 4 days in each of the top five states.

## Business recommendation (preliminary)

Tables and Bookcases generate substantial revenue but lose money, so they are the first place to look when trying to improve profit. This analysis shows *where* money is lost, not *why*. The next check is whether discount levels explain the losses, which I have not tested yet.

## Limitations

- The data is a public, fictional dataset, so the findings illustrate the method rather than describe a real business.
- Product names were reduced to one per product ID, so any analysis at the product-name level depends on that choice.
- Differences in margin between segments and sub-categories are descriptive. I have not tested whether they are statistically meaningful.
- The recommendation above is a hypothesis to test, not a conclusion.

## Roadmap

- [x] Normalized schema and ERD
- [x] Data cleaning and load, with validation
- [x] Join queries
- [ ] CTE queries (for example, top 10 customers and their share of total sales)
- [ ] Window-function queries (running monthly totals, product rank within category, year-over-year growth with `LAG()`)
- [ ] Dashboard in Tableau or R
- [ ] Check whether discounts explain the loss-making sub-categories

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
│   └── 01_joins.sql
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
   sqlite3 -header -column sales.db ".read queries/01_joins.sql"
   ```

## Tools

SQLite, DBeaver, Python, dbdiagram.io (ERD), Git.

## Learning log

See [`learning_log.md`](learning_log.md) for dated notes on what I learned and what I would improve.
