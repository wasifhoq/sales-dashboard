PRAGMA foreign_keys = OFF;

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS stg_superstore;

PRAGMA foreign_keys = ON;

CREATE TABLE customers (
    customer_id    TEXT PRIMARY KEY,
    customer_name  TEXT NOT NULL,
    segment        TEXT NOT NULL
);

CREATE TABLE products (
    product_id    TEXT PRIMARY KEY,
    product_name  TEXT NOT NULL,
    category      TEXT NOT NULL,
    sub_category  TEXT NOT NULL
);

CREATE TABLE orders (
    order_id     TEXT PRIMARY KEY,
    customer_id  TEXT NOT NULL REFERENCES customers (customer_id),
    order_date   TEXT NOT NULL,   
    ship_date    TEXT NOT NULL,   
    ship_mode    TEXT NOT NULL,
    country      TEXT NOT NULL,
    region       TEXT NOT NULL,
    state        TEXT NOT NULL,
    city         TEXT NOT NULL,
    postal_code  TEXT NOT NULL    
);

CREATE TABLE order_items (
    order_item_id  INTEGER PRIMARY KEY,
    order_id       TEXT NOT NULL REFERENCES orders (order_id),
    product_id     TEXT NOT NULL REFERENCES products (product_id),
    sales          REAL NOT NULL,
    quantity       INTEGER NOT NULL,
    discount       REAL NOT NULL,
    profit         REAL NOT NULL
);

CREATE TABLE stg_superstore (
    row_id, order_id, order_date, ship_date, ship_mode,
    customer_id, customer_name, segment, country, city, state,
    postal_code, region, product_id, category, sub_category,
    product_name, sales, quantity, discount, profit
);
