# LEARNING LOG

---

## Nov 13, 2026: Project Setup, Data Cleaning & SQLite Database Setup

### 1. Project Organization
- Started the `sales-dashboard` project with a clean folder structure:
  - `data/` for raw and cleaned CSV datasets.
  - `schema/` for ERD diagrams and SQL table definitions.
  - `queries/` for future analytical SQL queries.
  - `dashboard/` for reports and visualizations.
- Initialized Git and added a `.gitignore` to keep database binaries (`*.db`, `*.sqlite3`), virtual environments, and OS cache out of version control.

### 2. Data Preparation (`data/prepare_data.py`)
- The raw dataset is the Superstore sales dataset (`superstore_sample.csv`).
- The original file had character encoding issues (Windows `cp1252` encoding with non-breaking spaces `\xa0`).
- Wrote a Python script to convert and save it cleanly as UTF-8 (`superstore_clean.csv`) with 9,994 records and 21 columns.

### 3. Database Schema & Normalization
- Designed the relational database schema based on the ERD:
  - **`customers`**: Holds unique customer info (`customer_id`, `customer_name`, `segment`).
  - **`products`**: Holds product details (`product_id`, `product_name`, `category`, `sub_category`).
  - **`orders`**: Contains order level details (`order_id`, `customer_id`, `order_date`, `ship_date`, `ship_mode`, address fields).
  - **`order_items`**: Contains item level metrics (`sales`, `quantity`, `discount`, `profit`) linked to `orders` and `products`.

### 4. ETL & Loading Data with SQLite
- Installed the `sqlite3` command-line tool via `winget`.
- **Key Lesson on Environment Variables**: When installing software in Windows, existing open terminal sessions do not automatically see the new tool. Refreshing `$env:Path` or restarting the terminal solved the `command not found` error.
- Created `schema/create_tables.sql` with foreign key constraints.
- Used a staging table pattern in `schema/load_data.sql`:
  1. Imported the raw CSV directly into a temporary table `stg_superstore` using SQLite's `.mode csv` and `.import`.
  2. Extracted and normalized data into the target tables using `INSERT INTO ... SELECT ... GROUP BY`.
  3. Cleaned and formatted dates from `M/D/YYYY` into standard ISO `YYYY-MM-DD` using `substr()` and `printf()`.
  4. Dropped `stg_superstore` after loading.
- Final record counts in `sales.db`:
  - 793 customers
  - 1,862 products
  - 5,009 orders
  - 9,994 order items

### 5. Git & GitHub SSH Authentication
- Encountered a `403 Permission Denied` when pushing over HTTPS because Git Credential Manager was defaulting to another local account (`Alimul-Mahfuz`).
- Changed the remote URL to use the configured SSH host alias (`git@github-wasif:wasifhoq/sales-dashboard.git`). This routes the push through the dedicated SSH key (`id_ed25519_temp`) for `wasifhoq`.
