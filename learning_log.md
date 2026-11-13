# Learning Log

---

## 2026-11-13
- Set up project structure with `data/`, `schema/`, `queries/`, and `dashboard/` folders, along with Git and `.gitignore`.
- Converted raw `superstore_sample.csv` (cp1252 encoding) into clean UTF-8 `superstore_clean.csv` using Python.
- Designed ERD and normalized data into 4 relational tables: `customers`, `products`, `orders`, and `order_items`.
- Created `schema/create_tables.sql` with primary and foreign key constraints, plus a temporary `stg_superstore` staging table.
- Wrote `schema/load_data.sql` to import the CSV, transform date fields into `YYYY-MM-DD` format, populate all 4 tables, and clean up staging.
- Successfully built `sales.db` with 793 customers, 1,862 products, 5,009 orders, and 9,994 order items.
