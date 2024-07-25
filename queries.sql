-- запрос ниже считает общее количество покупателей из таблицы customers
select
	count(customer_id) as customers_count
from customers;

-- запрос ниже возвращает 10 лучших (по выручке) продавцов,
-- формирует их имя и фамилию, округляет выручку в меньшую сторону,
-- считает количество сделок каждого продавца
SELECT 
   CONCAT(employees.first_name, ' ', employees.last_name) AS seller,
   COUNT(sales.sales_id) AS operations,
   FLOOR(SUM(products.price * sales.quantity)) AS income
FROM sales
INNER JOIN employees ON sales.sales_person_id = employees.employee_id
INNER JOIN products ON sales.product_id = products.product_id
GROUP BY employees.employee_id, employees.first_name, employees.last_name
ORDER BY income DESC
LIMIT 10;

-- lowest_average_income
-- запрос ниже находит продавцов, чья средняя выручка за сделку
-- меньше средней выручки всех продавцов,
-- но сначала он вычисляет среднюю выручку за сделку для каждого продавца,
-- а затем сравнивает её с общей средней выручкой
-- и сортирует результаты по возрастанию.
SELECT 
    employees.first_name || ' ' || employees.last_name AS seller,
    FLOOR(SUM(sales.quantity * products.price) / COUNT(sales.sales_id)) AS average_income
FROM sales
INNER JOIN employees ON sales.sales_person_id = employees.employee_id
INNER JOIN products ON sales.product_id = products.product_id
GROUP BY employees.employee_id, employees.first_name, employees.last_name
HAVING FLOOR(SUM(sales.quantity * products.price) / COUNT(sales.sales_id)) < (
    SELECT 
        FLOOR(AVG(total_income)) AS avg_income
    FROM (
        SELECT 
            SUM(sales.quantity * products.price) / COUNT(sales.sales_id) AS total_income
        FROM sales
        INNER JOIN employees ON sales.sales_person_id = employees.employee_id
        INNER JOIN products ON sales.product_id = products.product_id
        GROUP BY employees.employee_id
    ) AS subquery
)
ORDER BY average_income;

-- day_of_the_week_income
-- запрос возвращает данные о выручке по дням недели.
-- Каждая запись содержит имя и фамилию продавца,
-- день недели и суммарную выручку.
-- Отсортирован по порядковому номеру дня недели и seller
SELECT
    employees.first_name || ' ' || employees.last_name AS seller,
    TO_CHAR(sales.sale_date, 'day') AS day_of_week,
    FLOOR(SUM(products.price * sales.quantity)) AS income
FROM sales
INNER JOIN employees ON sales.sales_person_id = employees.employee_id
INNER JOIN products ON sales.product_id = products.product_id
GROUP BY
    employees.first_name,
    employees.last_name,
    TO_CHAR(sales.sale_date, 'day'),
    EXTRACT(DOW FROM sales.sale_date)
ORDER BY
    (CASE
        WHEN EXTRACT(DOW FROM sales.sale_date) = 0 THEN 7
        ELSE EXTRACT(DOW FROM sales.sale_date)
    END),
    seller;
	
-- age_groups
-- запроас возвращает таблицу с количеством покупателей
-- в разных возрастных группах, отсортированную по возрастным группам
SELECT 
    CASE 
        WHEN age BETWEEN 16 AND 25 THEN '16-25'
        WHEN age BETWEEN 26 AND 40 THEN '26-40'
        WHEN age > 40 THEN '40+'
    END AS age_category,
    COUNT(*) AS age_count
FROM customers
GROUP BY age_category
ORDER BY age_category;
    
-- customers_by_month
-- запрос находит количество уникальных покупателей и их выручку,
-- группирует данные по дате и сортирует по дате по возрастанию
SELECT 
    TO_CHAR(sales.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT sales.customer_id) AS total_customers,
    FLOOR(SUM(products.price * sales.quantity)) AS income
FROM sales
INNER JOIN products ON sales.product_id = products.product_id
GROUP BY date
ORDER BY date;

-- special_offer
-- запрос найдёт покупателей, совершивших (самую) первую покупку с ценой равной нулю
-- и отсортирует по id покупателя
WITH TheSales AS (
    SELECT 
        sales.customer_id,
        sales.sale_date,
        sales.sales_person_id,
        sales.product_id,
        ROW_NUMBER() OVER (PARTITION BY sales.customer_id ORDER BY sales.sale_date, sales.sales_id) AS rank
    FROM sales
    INNER JOIN products ON sales.product_id = products.product_id
    WHERE products.price = 0
),
FirstSales AS (
    SELECT 
        customer_id,
        sale_date,
        sales_person_id,
        product_id
    FROM TheSales
    WHERE rank = 1
)
SELECT 
    CONCAT(customers.first_name, ' ', customers.last_name) AS customer,
    FirstSales.sale_date,
    CONCAT(employees.first_name, ' ', employees.last_name) AS seller
FROM FirstSales
INNER JOIN customers ON FirstSales.customer_id = customers.customer_id
INNER JOIN employees ON FirstSales.sales_person_id = employees.employee_id
ORDER BY customers.customer_id;