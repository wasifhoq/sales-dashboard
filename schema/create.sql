PRAGMA foreign_keys = OFF;

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;

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
    quantity       INTEGER NOT NULL,`
    discount       REAL NOT NULL,
    profit         REAL NOT NULL
);



PRAGMA foreign_keys = ON;


DROP TABLE IF EXISTS stg_superstore;
CREATE TABLE stg_superstore (
    row_id, order_id, order_date, ship_date, ship_mode,
    customer_id, customer_name, segment, country, city, state,
    postal_code, region, product_id, category, sub_category,
    product_name, sales, quantity, discount, profit
);


INSERT INTO customers (customer_id, customer_name, segment)
SELECT customer_id, MIN(customer_name), MIN(segment)
FROM stg_superstore
GROUP BY customer_id;


INSERT INTO products (product_id, product_name, category, sub_category)
SELECT product_id, MIN(product_name), MIN(category), MIN(sub_category)
FROM stg_superstore
GROUP BY product_id;


INSERT INTO orders (order_id, customer_id, order_date, ship_date, ship_mode,
                    country, region, state, city, postal_code)
SELECT
    order_id,
    MIN(customer_id),
    MIN(substr(order_date, -4) || '-'
        || printf('%02d', CAST(substr(order_date, 1, instr(order_date, '/') - 1) AS INTEGER)) || '-'
        || printf('%02d', CAST(substr(order_date, instr(order_date, '/') + 1,
                                      length(order_date) - instr(order_date, '/') - 5) AS INTEGER))),
    MIN(substr(ship_date, -4) || '-'
        || printf('%02d', CAST(substr(ship_date, 1, instr(ship_date, '/') - 1) AS INTEGER)) || '-'
        || printf('%02d', CAST(substr(ship_date, instr(ship_date, '/') + 1,
                                      length(ship_date) - instr(ship_date, '/') - 5) AS INTEGER))),
    MIN(ship_mode),
    MIN(country),
    MIN(region),
    MIN(state),
    MIN(city),
    MIN(printf('%05d', CAST(postal_code AS INTEGER)))
FROM stg_superstore
GROUP BY order_id;


INSERT INTO order_items (order_item_id, order_id, product_id,
                         sales, quantity, discount, profit)
SELECT CAST(row_id AS INTEGER), order_id, product_id,
       CAST(sales AS REAL), CAST(quantity AS INTEGER),
       CAST(discount AS REAL), CAST(profit AS REAL)
FROM stg_superstore;


DROP TABLE stg_superstore;