-- customers_count -- Запрос считает общее количество покупателей из таблицы customers
select
    count(customer_id) as customers_count
from
    customers;

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
    employees.employee_id,
    employees.first_name,
    employees.last_name
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
    floor(sum(sales.quantity * products.price) / count(sales.sales_id)) as average_income
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
    floor(sum(sales.quantity * products.price) / count(sales.sales_id)) < (
        select
            floor(avg(total_income)) as avg_income
        from (
            select
                sum(sales.quantity * products.price) / count(sales.sales_id) as total_income
            from
                sales
            inner join employees
                on sales.sales_person_id = employees.employee_id
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
    extract(dow from sales.sale_date)
order by
    (case
        when extract(dow from sales.sale_date) = 0 then 7
        else extract(dow from sales.sale_date)
    end),
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
-- Запрос найдёт покупателей, совершивших (самую) первую покупку с ценой равной нулю
-- и отсортирует по id покупателя
with the_sales as (
    select
        sales.customer_id,
        sales.sale_date,
        sales.sales_person_id,
        sales.product_id,
        row_number() over (
            partition by sales.customer_id
            order by sales.sale_date, sales.sales_id
        ) as rank
    from
        sales
    inner join products
        on sales.product_id = products.product_id
    where
        products.price = 0
),

first_sales as (
    select
        customer_id,
        sale_date,
        sales_person_id,
        product_id
    from
        the_sales
    where
        rank = 1
)

select
    customers.customer_id,
    concat(customers.first_name, ' ', customers.last_name) as customer,
    first_sales.sale_date,
    concat(employees.first_name, ' ', employees.last_name) as seller
from
    first_sales
inner join customers
    on first_sales.customer_id = customers.customer_id
inner join employees
    on first_sales.sales_person_id = employees.employee_id
order by
    customers.customer_id;
