-- Задание 1.

SELECT city, -- выбираем города
    CASE
        WHEN age BETWEEN 0 AND 20 THEN 'young' -- условие - группировка покупателей по возрасту
        WHEN age BETWEEN 21 AND 49 THEN 'adult'
        WHEN age >= 50 THEN 'old'
    END AS age_category,
    COUNT(*) AS total_users
FROM users
GROUP BY city, age_category -- группируем по городу и возрастной категории
ORDER BY city, total_users DESC -- сортировка по городу по возрастанию (алфавит), по количеству покупателей по убыванию


-- Задание 2.

SELECT category,
    ROUND(AVG(price), 2) AS avg_price -- расчет средней цены и округление до 2х знаков
FROM products
WHERE name ILIKE '%hair%' OR name ILIKE '%home%' -- ILIKE используется, чтобы найти все варианты содержания искомых слов (с любым регистром)
GROUP BY category -- группировка по категории


-- Задание 3.
  
SELECT seller_id,
    COUNT(DISTINCT category) AS total_categ, -- уникальные категории
    ROUND(AVG(rating), 2) AS avg_rating, -- средний округленный рейтинг
    SUM(revenue) AS total_revenue, -- сумма дохода
    CASE -- условие для определения категории
        WHEN COUNT(DISTINCT category) > 1 AND SUM(revenue) > 50000 THEN 'rich'
        WHEN COUNT(DISTINCT category) > 1 THEN 'poor'
        ELSE 'no_category' -- решила вывести всех, чтобы показать полностью данные
    END AS seller_type
FROM sellers
WHERE category != 'Bedding' -- Категория “Bedding” не должна учитываться в расчетах.
GROUP BY seller_id -- группировка
ORDER BY seller_id -- сортировка

  
-- Задание 4.

-- с использованием временных таблиц
WITH unsuccessful_sellers AS (
    SELECT seller_id,
        MIN(delivery_days) AS min_delivery_days, -- минимальный срок доставки
        MAX(delivery_days) AS max_delivery_days, -- максимальный срок доставки
        FLOOR((CURRENT_DATE - TO_DATE(date_reg, 'DD/MM/YYYY')) / 30) AS month_from_registration -- считаем кол-вол полных месяцев с преобразованием строки с датой в нужным формат и floor отбрасывает остаток
    FROM sellers
    WHERE category != 'Bedding' -- Категория “Bedding” по-прежнему не должна учитываться в расчетах.
  -- оставляем только не успешных селлеров
      AND seller_id IN (
          SELECT seller_id
          FROM sellers
          WHERE category != 'Bedding'
          GROUP BY seller_id
          HAVING COUNT(DISTINCT category) > 1 AND SUM(revenue) <= 50000
      )
    GROUP BY seller_id, date_reg
),
   -- вычисляем разницу в сроках доставки
delivery_difference AS (
    SELECT 
        MAX(max_delivery_days) - MIN(min_delivery_days) AS max_delivery_difference
    FROM unsuccessful_sellers
)
  -- выводим всю необходимую информацию
SELECT u.seller_id,
    u.month_from_registration,
    d.max_delivery_difference
FROM unsuccessful_sellers u, delivery_difference d
ORDER BY u.seller_id


-- Задание 5.

WITH selected_sellers AS (
    SELECT seller_id,
        ARRAY_AGG(DISTINCT category ORDER BY category) AS categories, -- собираем все категории в массив
        COUNT(DISTINCT category) AS total_categories, -- считаем уникальные категории
        SUM(revenue) AS total_revenue -- суммируем доход
    FROM sellers
    WHERE EXTRACT(YEAR FROM TO_DATE(date_reg, 'DD/MM/YYYY')) = 2022 -- отбираем селлеров от 2022 года 
    GROUP BY seller_id
  -- отбираем с условием по категориям и суммарному доходу
    HAVING COUNT(DISTINCT category) = 2 
       AND SUM(revenue) > 75000
)
SELECT seller_id,
    categories[1] || ' - ' || categories[2] AS category_pair -- соединям в пары категории товаров
FROM selected_sellers
ORDER BY seller_id

