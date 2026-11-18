

library(DBI)
library(RSQLite)
library(ggplot2)
library(dplyr)
library(scales)

db_path <- file.path(getwd(), "sales.db")
if (!file.exists(db_path)) {
  db_path <- file.path(getwd(), "..", "sales.db")
}
con <- dbConnect(RSQLite::SQLite(), db_path)

output_dir <- if (basename(getwd()) == "dashboard") "." else "dashboard"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

message("Connected to: ", db_path)
message("Saving plots to: ", normalizePath(output_dir))


q1 <- "
SELECT 
    substr(o.order_date, 1, 7) AS month,
    SUM(oi.sales)              AS revenue,
    SUM(oi.profit)             AS profit
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
GROUP BY substr(o.order_date, 1, 7)
ORDER BY month;
"
df_monthly <- dbGetQuery(con, q1) %>%
  mutate(date = as.Date(paste0(month, "-01")))

p1 <- ggplot(df_monthly, aes(x = date)) +
  geom_line(aes(y = revenue, color = "Revenue"), linewidth = 1) +
  geom_point(aes(y = revenue, color = "Revenue"), size = 1.8) +
  geom_line(aes(y = profit, color = "Profit"), linewidth = 1) +
  geom_point(aes(y = profit, color = "Profit"), size = 1.8) +
  scale_y_continuous(labels = label_dollar(scale = 1e-3, suffix = "k")) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +
  scale_color_manual(values = c("Revenue" = "#1f77b4", "Profit" = "#2ca02c")) +
  labs(
    title = "Monthly Revenue and Profit Over Time (2014 - 2017)",
    subtitle = "Revenue surges toward year-end holiday peaks; profit tracks consistently positive",
    x = "Order Month",
    y = "Amount ($USD)",
    color = "Metric"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "top",
    plot.title = element_text(face = "bold", size = 14),
    panel.grid.minor = element_blank()
  )

ggsave(file.path(output_dir, "01_monthly_revenue_profit.png"), p1, width = 9, height = 5, dpi = 300)
message("Saved: 01_monthly_revenue_profit.png")


q2 <- "
WITH banded AS (
    SELECT
        CASE
            WHEN discount = 0    THEN '1) No discount'
            WHEN discount <= 0.2 THEN '2) 1-20%'
            WHEN discount <= 0.4 THEN '3) 21-40%'
            ELSE                      '4) Over 40%'
        END AS discount_band,
        sales,
        profit
    FROM order_items
)
SELECT
    discount_band,
    SUM(sales)  AS revenue,
    SUM(profit) AS profit,
    ROUND(100.0 * SUM(profit) / SUM(sales), 1) AS margin_pct
FROM banded
GROUP BY discount_band
ORDER BY discount_band;
"
df_discount <- dbGetQuery(con, q2) %>%
  mutate(
    status = ifelse(margin_pct >= 0, "Profitable", "Loss-Making"),
    label = sprintf("%+.1f%%", margin_pct)
  )

p2 <- ggplot(df_discount, aes(x = discount_band, y = margin_pct, fill = status)) +
  geom_col(width = 0.55, show.legend = FALSE) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black", linewidth = 0.6) +
  geom_text(
    aes(
      label = label,
      vjust = ifelse(margin_pct >= 0, -0.6, 1.4)
    ),
    fontface = "bold",
    size = 4
  ) +
  scale_fill_manual(values = c("Profitable" = "#1f77b4", "Loss-Making" = "#d9534f")) +
  scale_y_continuous(
    labels = label_percent(scale = 1),
    limits = c(-90, 40)
  ) +
  labs(
    title = "Profit Margin by Discount Level",
    subtitle = "Margins plunge severely below zero once discount rate exceeds 20%",
    x = "Discount Band",
    y = "Profit Margin (%)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    panel.grid.minor = element_blank()
  )

ggsave(file.path(output_dir, "02_discount_margin.png"), p2, width = 8, height = 5, dpi = 300)
message("Saved: 02_discount_margin.png")


q3 <- "
SELECT 
    p.sub_category,
    ROUND(SUM(oi.profit), 2) AS profit,
    ROUND(SUM(oi.sales), 2)  AS revenue,
    ROUND(100.0 * SUM(oi.profit) / SUM(oi.sales), 1) AS margin_pct
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
GROUP BY p.sub_category
ORDER BY profit ASC;
"
df_subcat <- dbGetQuery(con, q3) %>%
  mutate(
    sub_category = reorder(sub_category, profit),
    loss_flag = ifelse(profit < 0, "Loss", "Profit"),
    label = ifelse(profit < 0,
                   sprintf("-$%s (%.1f%%)", format(round(abs(profit)), big.mark = ","), margin_pct),
                   sprintf("+$%s (%.1f%%)", format(round(profit), big.mark = ","), margin_pct))
  )

p3 <- ggplot(df_subcat, aes(x = profit, y = sub_category, fill = loss_flag)) +
  geom_col(width = 0.7, show.legend = FALSE) +
  geom_vline(xintercept = 0, linetype = "solid", color = "gray40", linewidth = 0.5) +
  geom_text(
    aes(
      label = label,
      hjust = ifelse(profit < 0, 1.1, -0.1)
    ),
    size = 3.3,
    fontface = "bold"
  ) +
  scale_fill_manual(values = c("Loss" = "#d9534f", "Profit" = "#2c7bb6")) +
  scale_x_continuous(
    labels = label_dollar(scale = 1e-3, suffix = "k"),
    expand = expansion(mult = c(0.18, 0.22))
  ) +
  labs(
    title = "Total Profit by Sub-Category (Losses in Red)",
    subtitle = "Tables (-$17.7k), Bookcases (-$3.5k), and Supplies (-$1.2k) are operating at net losses",
    x = "Cumulative Profit ($USD)",
    y = "Sub-Category"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    panel.grid.minor = element_blank()
  )

ggsave(file.path(output_dir, "03_subcat_profit_losses_red.png"), p3, width = 9.5, height = 6.5, dpi = 300)
message("Saved: 03_subcat_profit_losses_red.png")


q4 <- "
SELECT 
    c.segment,
    SUM(oi.sales)  AS revenue,
    SUM(oi.profit) AS profit,
    ROUND(100.0 * SUM(oi.profit) / SUM(oi.sales), 1) AS margin_pct
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
JOIN customers c ON c.customer_id = o.customer_id
GROUP BY c.segment
ORDER BY revenue DESC;
"
df_segment <- dbGetQuery(con, q4) %>%
  mutate(
    segment = reorder(segment, -revenue),
    label = sprintf("$%s\n(Margin: %.1f%%)", format(round(revenue), big.mark = ","), margin_pct)
  )

p4 <- ggplot(df_segment, aes(x = segment, y = revenue, fill = segment)) +
  geom_col(width = 0.55, show.legend = FALSE) +
  geom_text(aes(label = label), vjust = -0.3, size = 4, fontface = "bold", lineheight = 0.9) +
  scale_fill_manual(values = c("Consumer" = "#386cb0", "Corporate" = "#7fc97f", "Home Office" = "#fdc086")) +
  scale_y_continuous(
    labels = label_dollar(scale = 1e-6, suffix = "M"),
    limits = c(0, 1.4e6)
  ) +
  labs(
    title = "Total Revenue by Customer Segment (Labelled with Margin %)",
    subtitle = "Consumer drives greatest sales volume, but Home Office generates the highest profit margin",
    x = "Customer Segment",
    y = "Total Revenue ($USD)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    panel.grid.minor = element_blank()
  )

ggsave(file.path(output_dir, "04_segment_revenue_margin.png"), p4, width = 8, height = 5, dpi = 300)
message("Saved: 04_segment_revenue_margin.png")


q5 <- "
WITH yearly AS (
    SELECT
        substr(o.order_date, 1, 4) AS year,
        SUM(oi.sales)              AS revenue,
        SUM(oi.profit)             AS profit
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    GROUP BY substr(o.order_date, 1, 4)
)
SELECT
    year,
    revenue,
    profit,
    COALESCE(ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY year))
             / LAG(revenue) OVER (ORDER BY year), 1), 0.0) AS yoy_growth_pct
FROM yearly
ORDER BY year;
"
df_yearly <- dbGetQuery(con, q5) %>%
  mutate(
    label = ifelse(yoy_growth_pct == 0,
                   sprintf("$%sk\n(Baseline)", round(revenue / 1000)),
                   sprintf("$%sk\n(YoY: %+.1f%%)", round(revenue / 1000), yoy_growth_pct))
  )

p5 <- ggplot(df_yearly, aes(x = year, y = revenue)) +
  geom_col(fill = "#4a7bb0", width = 0.55) +
  geom_text(aes(label = label), vjust = -0.3, size = 3.8, fontface = "bold", lineheight = 0.9) +
  scale_y_continuous(
    labels = label_dollar(scale = 1e-3, suffix = "k"),
    limits = c(0, 8.5e5)
  ) +
  labs(
    title = "Annual Revenue & Year-over-Year Growth (YoY %)",
    subtitle = "Calculated using SQL LAG() window function; strong acceleration in 2016 and 2017",
    x = "Year",
    y = "Total Revenue ($USD)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    panel.grid.minor = element_blank()
  )

ggsave(file.path(output_dir, "05_yoy_annual_growth.png"), p5, width = 8, height = 5, dpi = 300)
message("Saved: 05_yoy_annual_growth.png")

dbDisconnect(con)
message("All 5 charts successfully generated and saved to: ", normalizePath(output_dir))
