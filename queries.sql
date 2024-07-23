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
FROM
   sales
INNER JOIN
   employees ON sales.sales_person_id = employees.employee_id
INNER JOIN
   products ON sales.product_id = products.product_id
GROUP BY
   employees.employee_id, employees.first_name, employees.last_name
ORDER BY
   income DESC
LIMIT 10;

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

-- запрос ниже данные информацию о выручке по дням недели.
-- Каждая запись содержит имя и фамилию продавца,
-- день недели и суммарную выручку.
-- Отсортирован по порядковому номеру дня недели и seller
SELECT
    employees.first_name || ' ' || employees.last_name AS seller,
    TO_CHAR(sales.sale_date, 'Day') AS day_of_week,
    FLOOR(SUM(products.price * sales.quantity)) AS income
FROM
    sales
INNER JOIN
    employees ON sales.sales_person_id = employees.employee_id
INNER JOIN
    products ON sales.product_id = products.product_id
GROUP BY
    employees.first_name,
    employees.last_name,
    TO_CHAR(sales.sale_date, 'Day'),
    EXTRACT(DOW FROM sales.sale_date)
ORDER BY
    (CASE
        WHEN EXTRACT(DOW FROM sales.sale_date) = 0 THEN 7
        ELSE EXTRACT(DOW FROM sales.sale_date)
    END),
	seller;