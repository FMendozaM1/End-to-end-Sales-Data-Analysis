# End-to-end-Sales-Data-Analysis

## Description

This project was developed, focusing on **data cleaning, transformation, and analysis** of retail orders using **Python (pandas)** and **SQL**.
The main goal was to transform raw order data into a structured database and then extract meaningful business insights through queries.

---

## Project Structure

- **Python Notebook** → Data preprocessing and cleaning
- **CSV Dataset** → Retail orders data
- **SQL Queries** → Analytical queries to extract insights

---

## Data Preprocessing (Python)

Using **pandas**, the following steps were performed:

1. **Import libraries and load dataset**

   ```python
   import kaggle
   import pandas as pd
   db = pd.read_csv("orders.csv", na_values=['Not Available', 'unknown'])
   ```

2. **Data cleaning**
   - Renamed all columns to lowercase and replaced spaces with `_`
   - Converted `order_date` column to datetime format
   - Checked and standardized categorical values (e.g., `ship_mode`)

3. **Feature engineering**
   - Created a new `discount` column

    ```python
   db["discount"] = db["list_price"] * db["discount_percent"] * 0.01
    ```
   - Created a `sale_price` column

   ```python
   db["sale_price"] = db["list_price"] - db["discount"]
    ```
   - Created a `profit` column

   ```python
   db["profit"] = db["sale_price"] - db["cost_price"]
    ```

4. **Final cleanup**
   - Dropped unused columns: `cost_price`, `list_price`, `discount_percent`

---

## SQL Analysis

After cleaning, the dataset was imported into a SQL database (`db_orders`) for analysis.

**Queries provided insights into:**

- Top 10 highest revenue generating products

```SQL
SELECT TOP 10 product_id, SUM(sale_price) AS total_revenue
FROM db_orders
GROUP BY product_id
ORDER BY total_revenue DESC;
```

- Top 5 highest selling products in each region

```SQL
WITH cte AS (
    SELECT region, product_id, SUM(sale_price) AS total_revenue
    FROM db_orders
    GROUP BY region, product_id
)
SELECT * FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY region ORDER BY total_revenue DESC) AS rn
    FROM cte
) A
WHERE rn <= 5;
```

- Month-over-month growth comparison (2022 vs 2023)

```SQL
WITH cte AS (
    SELECT YEAR(order_date) AS year_is, MONTH(order_date) AS month_is, SUM(sale_price) AS total_revenue
    FROM db_orders
    GROUP BY YEAR(order_date), MONTH(order_date)
)
SELECT
    month_is,
    SUM(CASE WHEN year_is = 2022 THEN total_revenue ELSE 0 END) AS revenue_2022,
    SUM(CASE WHEN year_is = 2023 THEN total_revenue ELSE 0 END) AS revenue_2023
FROM cte
GROUP BY month_is
ORDER BY month_is;
```


- Month with highest sales per category

```SQL
WITH cte AS (
    SELECT category, FORMAT(order_date, 'yyyyMM') AS year_month, SUM(sale_price) AS total_revenue
    FROM db_orders
    GROUP BY category, FORMAT(order_date, 'yyyyMM')
)
SELECT *
FROM (
    SELECT *, ROW_NUMBER() OVER(PARTITION BY category ORDER BY total_revenue DESC) AS rn
    FROM cte
) a
WHERE rn = 1;
```

- Sub-category with highest profit growth (2023 vs 2022)

```SQL
WITH cte AS (
    SELECT sub_category, YEAR(order_date) AS year_is, SUM(sale_price) AS total_revenue
    FROM db_orders
    GROUP BY sub_category, YEAR(order_date)
),
cte2 AS (
    SELECT sub_category,
           SUM(CASE WHEN year_is = 2022 THEN total_revenue ELSE 0 END) AS revenue_2022,
           SUM(CASE WHEN year_is = 2023 THEN total_revenue ELSE 0 END) AS revenue_2023
    FROM cte
    GROUP BY sub_category
)
SELECT TOP 1 *, (revenue_2023 - revenue_2022) * 100.0 / revenue_2022 AS percentage_growth
FROM cte2
ORDER BY (revenue_2023 - revenue_2022) * 100.0 / revenue_2022 DESC;
```
---
