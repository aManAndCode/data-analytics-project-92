-- customers_count -- Запрос считает всех покупателей из таблицы customers
select count(customer_id) as customers_count from customers;

-- top_sellers
-- Запрос возвращает 10 лучших (по выручке) продавцов,
-- формирует их имя и фамилию, округляет выручку в меньшую сторону,
-- считает количество сделок каждого продавца
select
    concat(employees.first_name, ' ', employees.last_name) as seller,
    count(sales.sales_id) as operations,
    floor(sum(products.price * sales.quantity)) as income
from
    sales
inner join employees
    on sales.sales_person_id = employees.employee_id
inner join products
    on sales.product_id = products.product_id
group by
    employees.employee_id
order by
    income desc
limit 10;

-- lowest_average_income
-- Запрос находит продавцов, чья средняя выручка за сделку
-- меньше средней выручки всех продавцов,
-- но сначала он вычисляет среднюю выручку за сделку для каждого продавца,
-- а затем сравнивает её с общей средней выручкой
-- и сортирует результаты по возрастанию.
select
    employees.first_name || ' ' || employees.last_name as seller,
    floor(avg(sales.quantity * products.price)) as average_income
from
    sales
inner join employees
    on sales.sales_person_id = employees.employee_id
inner join products
    on sales.product_id = products.product_id
group by
    employees.employee_id,
    employees.first_name,
    employees.last_name
having
    floor(avg(sales.quantity * products.price)) < (
        select floor(avg(total_income)) as avg_income
        from (
            select avg(sales.quantity * products.price) as total_income
            from
                sales
            inner join products
                on sales.product_id = products.product_id
            group by
                employees.employee_id
        ) as subquery
    )
order by
    average_income;

-- day_of_the_week_income
-- Запрос возвращает данные о выручке по дням недели.
-- Каждая запись содержит имя и фамилию продавца,
-- день недели и суммарную выручку.
-- Отсортирован по порядковому номеру дня недели и seller
select
    employees.first_name || ' ' || employees.last_name as seller,
    to_char(sales.sale_date, 'day') as day_of_week,
    floor(sum(products.price * sales.quantity)) as income
from
    sales
inner join employees
    on sales.sales_person_id = employees.employee_id
inner join products
    on sales.product_id = products.product_id
group by
    employees.first_name,
    employees.last_name,
    to_char(sales.sale_date, 'day'),
    extract(isodow from sales.sale_date)
order by
    extract(isodow from sales.sale_date),
    seller;

-- age_groups
-- Запрос возвращает таблицу с количеством покупателей
-- в разных возрастных группах, отсортированную по возрастным группам
select
    case
        when age between 16 and 25 then '16-25'
        when age between 26 and 40 then '26-40'
        when age > 40 then '40+'
    end as age_category,
    count(*) as age_count
from
    customers
group by
    age_category
order by
    age_category;

-- customers_by_month
-- Запрос находит количество уникальных покупателей и их выручку,
-- группирует данные по дате и сортирует по дате по возрастанию
select
    to_char(sales.sale_date, 'YYYY-MM') as selling_month,
    count(distinct sales.customer_id) as total_customers,
    floor(sum(products.price * sales.quantity)) as income
from
    sales
inner join products
    on sales.product_id = products.product_id
group by
    selling_month
order by
    selling_month;

-- special_offer
-- Запрос найдёт покупателей,
-- совершивших (самую) первую покупку с ценой равной нулю
-- и отсортирует по id покупателя
-- вариант 2.1 (с использованием distinct on / без подзапросов)
select distinct on (sales.customer_id)
    sales.sale_date,
    concat(customers.first_name, ' ', customers.last_name) as customer,
    concat(employees.first_name, ' ', employees.last_name) as seller
from
    sales
inner join products
    on sales.product_id = products.product_id
inner join customers
    on sales.customer_id = customers.customer_id
inner join employees
    on sales.sales_person_id = employees.employee_id
where
    products.price = 0
order by
    sales.customer_id;
