
--Top 10 highest revenue generating products
SELECT top 10
    product_id, 
    SUM(sale_price) AS total_revenue
FROM db_orders AS sales
GROUP BY product_id
ORDER BY total_revenue DESC
;

--Top 5 highest selling products in each region
WITH cte as (
SELECT region, product_id, sum(sale_price) as total_revenue
FROM db_orders
GROUP BY region, product_id)
SELECT * FROM (
SELECT *, ROW_NUMBER() OVER (PARTITION BY region ORDER BY total_revenue desc) as rn
FROM cte) A
WHERE rn <= 5;

--month over month growth comparison for 2022 and 2023 sales eg: jan 2022 vs jan 2023
WITH cte AS (
    SELECT 
        YEAR(order_date) AS year_is, 
        MONTH(order_date) AS month_is, 
        SUM(sale_price) AS total_revenue  
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

--month with highest sales for each category
;WITH cte AS (
    SELECT 
        category, 
        FORMAT(order_date, 'yyyyMM') AS year_month,
        SUM(sale_price) AS total_revenue
    FROM db_orders
    GROUP BY 
        category, 
        FORMAT(order_date, 'yyyyMM')
)
SELECT *
FROM (
    SELECT 
        *,
        ROW_NUMBER() OVER(PARTITION BY category ORDER BY total_revenue DESC) AS rn
    FROM cte
) a
WHERE rn = 1;

--Sub category with highest growth profit in 2023 compare to 2022

;WITH cte AS (
    SELECT 
        sub_category,
        YEAR(order_date) AS year_is, 
        SUM(sale_price) AS total_revenue  
    FROM db_orders
    GROUP BY sub_category, YEAR(order_date)
),
cte2 AS (
    SELECT 
        sub_category, 
        SUM(CASE WHEN year_is = 2022 THEN total_revenue ELSE 0 END) AS revenue_2022,
        SUM(CASE WHEN year_is = 2023 THEN total_revenue ELSE 0 END) AS revenue_2023
    FROM cte
    GROUP BY sub_category
)
SELECT TOP 1 
    *, 
    (revenue_2023 - revenue_2022) * 100.0 / revenue_2022 AS percentage_growth
FROM cte2
ORDER BY (revenue_2023 - revenue_2022) * 100.0 / revenue_2022 DESC
