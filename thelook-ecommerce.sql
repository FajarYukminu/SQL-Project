--1. Create a query to get the number of unique users, number of orders, and total sale price per status and month.
--
SELECT DATE_TRUNC(date(created_at), month) AS month
    ,COUNT(DISTINCT user_id) AS total_users 
    ,COUNT(order_id) AS total_orders
    ,ROUND(SUM(sale_price)) AS total_sales
FROM `bigquery-public-data.thelook_ecommerce.order_items` 
WHERE created_at BETWEEN '2019-01-01' AND '2022-08-31'
    AND status = 'Complete'
GROUP BY 1
ORDER BY 1 ;

--2. Create a query to get frequencies, average order value and total number of unique users where status is complete grouped by month
--
SELECT DATE_TRUNC(date(created_at), month) AS month
  ,ROUND(SUM(sale_price)/COUNT(DISTINCT order_id),2) AS price_per_order
  ,COUNT(DISTINCT user_id) AS unique_buyers
FROM `bigquery-public-data.thelook_ecommerce.order_items` 
WHERE created_at BETWEEN '2019-01-01' AND '2022-08-31'
  AND status = "Complete"
GROUP BY 1
ORDER BY 1 ;


-- 3. Find the user id, email, first and last name of users whose status is refunded on Aug 22 
--
SELECT t1.id AS user_id
  ,t1.email AS email
  ,t1.first_name AS first_name
  ,t1.last_name AS last_name
  ,t2.status AS status
FROM `bigquery-public-data.thelook_ecommerce.users` t1
INNER JOIN `bigquery-public-data.thelook_ecommerce.orders` t2
  ON t1.id = t2.user_id
WHERE t2.returned_at BETWEEN '2022-08-01'AND '2022-08-31'
LIMIT 100 ;

--4. Get the top 5 least and most profitable product over all time
--
WITH ct1 AS (
SELECT EXTRACT (year from t2.created_at) AS year
  ,t1.product_id
  ,product_name
  ,CAST(product_retail_price AS INT64) AS retail_price
  ,CAST(cost AS INT64) AS cost
  ,CAST(product_retail_price - cost AS INT64) AS profit
FROM `bigquery-public-data.thelook_ecommerce.inventory_items` AS t1
JOIN `bigquery-public-data.thelook_ecommerce.order_items` AS t2
ON t1.id = t2.inventory_item_id
WHERE t2.status = 'Complete'
)

, ct2 AS (
  SELECT ct1.year AS year
  ,ct1.product_id AS productid
  ,ct1.product_name AS productname
  ,SUM(ct1.retail_price) AS retail_price
  ,SUM(ct1.cost) AS cost
  ,SUM(ct1.profit) AS profit
  FROM ct1
  GROUP BY 1,2,3
  ORDER BY 1
  )

(SELECT productid, productname, retail_price,cost,profit
FROM ct2
ORDER BY 5 DESC
LIMIT 5)
UNION ALL
(SELECT productid, productname, retail_price,cost,profit
FROM ct2
ORDER BY 5 ASC
LIMIT 5) ;

--5.Create a query to get MONTH to DATE of TOTAL profit in each product categories of past 3 MONTHS(current date 15 AUG 2022) breakdown BY MONTH AND CATEGORIES
WITH ct1 AS (
  SELECT DATE(t1.created_at) AS order_date
      ,product_category AS categories
      ,ROUND(SUM(product_retail_price - cost),2) AS profit
  FROM `bigquery-public-data.thelook_ecommerce.inventory_items` AS t1
  INNER JOIN `bigquery-public-data.thelook_ecommerce.order_items` AS t2
  ON t1.id = t2.inventory_item_id 
  WHERE t1.created_at BETWEEN '2022-05-15' AND '2022-08-15'
  AND t2.status = 'Complete'
  GROUP BY 1,2
  ORDER BY 2,1
), 

ct2_table AS
( SELECT order_date,
         categories,
         profit,
         SUM(profit) OVER(PARTITION BY categories, EXTRACT(MONTH FROM order_date) ORDER BY categories, order_date) AS profit_categories
    FROM ct1
    ORDER BY 2,1
)

SELECT order_date,categories,profit_categories
FROM ct2_table
WHERE order_date BETWEEN "2022-06-01" AND "2022-08-16"
      AND EXTRACT(DAY FROM order_date) = 15 ;

