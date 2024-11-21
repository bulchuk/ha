-- Часть 1. Задание 1. 

-- временная таблица
WITH order_wait AS (
    SELECT o.customer_id,
        c.name AS customer_name,
        o.order_id,
        CAST(o.shipment_date AS DATE) - CAST(o.order_date AS DATE) AS wait_time -- вычисляем время ожидания
    FROM orders_new o
    JOIN customers_new c -- соединяем таблицы
    ON o.customer_id = c.customer_id 
    WHERE o.shipment_date IS NOT NULL -- исключаем заказы, которые не доставлены
)
SELECT customer_id, customer_name,
    MAX(wait_time) AS max_wait_time -- выбираем клиента с максимальными данными 
FROM order_wait
GROUP BY customer_id, customer_name
ORDER BY max_wait_time DESC
LIMIT 1


-- Часть 1. Задание 2.

WITH customer_stats AS (
    SELECT o.customer_id, 
        c.name AS customer_name,
        COUNT(o.order_id) AS total_orders, -- общее количество заказов
        AVG(CAST(o.shipment_date AS DATE) - CAST(o.order_date AS DATE)) AS avg_wait_time, -- среднее время ожидания
        SUM(o.order_ammount) AS total_order_amount -- общая сумма заказов
    FROM orders_new o
    JOIN customers_new c
    ON o.customer_id = c.customer_id
    WHERE o.shipment_date IS NOT NULL -- учитываем только доставленные заказы
    GROUP BY o.customer_id, c.name
)
SELECT customer_id, customer_name, total_orders, 
	avg_wait_time, total_order_amount
FROM customer_stats
ORDER BY total_order_amount DESC -- сортируем в порядке убывания общей суммы заказов


-- Часть 1. Задание 3.

WITH order_status AS (
    SELECT o.customer_id,
        c.name AS customer_name,
        SUM(
            CASE 
                WHEN CAST(o.shipment_date AS DATE) - CAST(o.order_date AS DATE) > 5 THEN 1 -- заказы с задержкой доставки более 5 дней
                ELSE 0 
            END
        ) AS delayed_orders,
        SUM(
            CASE 
                WHEN o.order_status = 'Cancel' THEN 1 -- отмененные заказы
                ELSE 0 
            END
        ) AS cancelled_orders,
        SUM(o.order_ammount) AS total_order_amount -- общая сумма заказов
    FROM orders_new o
    JOIN customers_new c
    ON o.customer_id = c.customer_id
    GROUP BY o.customer_id, c.name
)
SELECT customer_name, delayed_orders, cancelled_orders, total_order_amount
FROM order_status
WHERE delayed_orders > 0 OR cancelled_orders > 0 -- оставляем только тех, у кого были задержки или отмены
ORDER BY total_order_amount DESC -- сортируем по общей сумме заказов в порядке убывания


-- Часть 2. Задание 1.

SELECT p.product_category AS category,
    SUM(o.order_ammount) AS total_sales
FROM orders o
JOIN products p -- соединяем таблицы
ON o.product_id = p.product_id
GROUP BY p.product_category -- группируем по категории
ORDER BY total_sales DESC

-- Часть 2. Задание 2.

SELECT p.product_category AS category,
    SUM(o.order_ammount) AS total_sales
FROM orders o
JOIN products p -- соединяем таблицы
ON o.product_id = p.product_id
GROUP BY p.product_category -- группируем по категории
ORDER BY total_sales DESC
LIMIT 1 


-- Часть 2. Задание 3.

WITH top_product AS ( -- вычисления суммы продаж для каждого продукта в каждой категории
	SELECT p.product_category,
        p.product_id,
        p.product_name,
        SUM(o.order_ammount) AS product_sales -- сумма продаж
    FROM orders o
    JOIN products p 
    ON o.product_id = p.product_id
    GROUP BY p.product_category, p.product_id, p.product_name -- группируем по категории, идентификатору продукта и названию продукта
)
SELECT tp.product_category, -- выбираем категорию продукта
    tp.product_name, -- продукт с максимальной суммой продаж в категории
    tp.product_sales -- сумма продаж этого продукта
FROM top_product tp
WHERE tp.product_sales = (
        SELECT MAX(product_sales) -- подзапрос, который находит максимальную сумму продаж для каждой категории
        FROM top_product
        WHERE product_category = tp.product_category
    )
ORDER BY tp.product_category

