.mode csv
.import --skip 1 data/superstore_clean.csv stg_superstore

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
