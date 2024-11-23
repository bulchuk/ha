-- Часть 1. Задание 1.

-- временная таблица для вычисления максимальной зарплаты
WITH max_salary_by_industry AS (
    SELECT industry,
        MAX(salary) AS max_salary -- вычисляем максимальную зарплату по каждому направлению 
    FROM salary
    GROUP BY industry
),
  -- временная таблица для определения данных работника с максимальной зарплатой
highest_salary_employees AS (
    SELECT s.first_name, s.last_name, s.salary, s.industry,
        CONCAT(s.first_name, ' ', s.last_name) AS name_highest_sal -- соединяем фамилию и имя сотрудника
    FROM salary s
    INNER JOIN max_salary_by_industry msi
    ON s.industry = msi.industry AND s.salary = msi.max_salary
)
SELECT first_name, last_name, salary, industry, name_highest_sal
FROM highest_salary_employees

-- с использованием оконных функций
WITH ranked_employees AS (
    SELECT first_name, last_name, salary, industry,
        -- находим имя сотрудника с самой высокой зарплатой в каждом отделе
        FIRST_VALUE(CONCAT(first_name, ' ', last_name)) -- используем FIRST_VALUE, чтобы выбрать имя и фамилию сотрудника с самой высокой зарплатой
            OVER (PARTITION BY industry ORDER BY salary DESC) AS name_highest_sal,
        RANK() OVER (PARTITION BY industry ORDER BY salary DESC) AS rank -- присваиваем ранг сотрудникам внутри отдела на основе зарплаты, по убыванию
    FROM Salary
)
SELECT first_name, last_name, salary, industry, name_highest_sal
FROM ranked_employees
WHERE rank = 1 -- выбираем только тех сотрудников, у которых максимальная зарплата


-- Часть 1. Задание 2.

-- находим минимальную зарплату по каждому направлению 
WITH min_salary_by_industry AS (
    SELECT industry,                
        MIN(salary) AS min_salary
    FROM Salary
    GROUP BY industry     
),
-- соединяем исходные данные с таблицей минимальных зарплат по отделам
lowest_salary_employees AS (
    SELECT s.first_name, s.last_name, s.salary, s.industry, 
        CONCAT(s.first_name, ' ', s.last_name) AS name_lowest_sal  -- соединяем фамилию и имя сотрудника
    FROM Salary s
    INNER JOIN min_salary_by_industry msi
    ON s.industry = msi.industry AND s.salary = msi.min_salary -- находим сотрудников с минимальной зарплатой
)
SELECT first_name, last_name, salary, industry, name_lowest_sal
FROM lowest_salary_employees

  
-- с использованием оконных функций
WITH ranked_employees AS (
    SELECT first_name, last_name, salary, industry,
  -- находим имя сотрудника с минимальной зарплатой в отделе
        FIRST_VALUE(first_name || ' ' || last_name) -- соединяем фамилию и имя сотрудника
            OVER (PARTITION BY industry ORDER BY salary ASC) AS name_lowest_sal,
  -- присваиваем уникальный порядковый номер сотрудникам в пределах отдела на основе зарплаты
        ROW_NUMBER() OVER (PARTITION BY industry ORDER BY salary ASC) AS rank
    FROM salary
)
SELECT first_name, last_name, salary, industry, name_lowest_sal        
FROM ranked_employees
WHERE rank = 1



-- Часть 2. Задание 1.

SELECT s.shop_number,                    
    sh.city,  
    sh.address,    
    SUM(s.quantity) AS sum_qty, -- суммируем количество товаров
    SUM(s.quantity * g.price) AS sum_qty_price -- сумма покупок
FROM sales s
JOIN shops sh ON s.shop_number = sh.shop_number -- присоединяем таблицу магазинов
JOIN goods g ON s.good_id = g.good_id        -- присоединяем таблицу товаров   
WHERE s.date = '2016-02-01'        -- отбираем нужную дату            
GROUP BY s.shop_number, sh.city, sh.address 
ORDER BY s.shop_number  


-- Часть 2. Задание 2.

SELECT s.date AS date_,                             
    sh.city,  
    -- вычисляем долю продаж
    SUM(s.quantity * g.price) / -- сумма продаж в конкретном городе
    SUM(SUM(s.quantity * g.price)) OVER (PARTITION BY s.date) AS sum_sales_rel -- сумма всех продаж в рублях для каждой даты
FROM sales s
JOIN shops sh ON s.shop_number = sh.shop_number    -- присоединяем таблицу магазинов
JOIN goods g ON s.good_id = g.good_id             -- присоединяем таблицу товаров   
WHERE g.category = 'ЧИСТОТА'               -- отбираем только категорию "Чистота"        
GROUP BY s.date, sh.city                               
ORDER BY s.date, sh.city  


-- Часть 2. Задание 3.

-- временная таблица
WITH ranked_goods AS (
    SELECT s.date AS date_,              
        s.shop_number,                
        s.good_id,                    
        SUM(s.quantity) AS total_qty, -- суммарное количество продаж товара
        RANK() OVER (
            PARTITION BY s.date, s.shop_number  -- разделяем по дате и номеру магазина
            ORDER BY SUM(s.quantity) DESC    -- сортируем по количеству продаж, по убыванию
        ) AS rnk                  -- присваиваем ранг       
    FROM  sales s
    GROUP BY s.date, s.shop_number, s.good_id 
)
SELECT date_, shop_number, good_id
FROM ranked_goods
WHERE rnk <= 3 -- отбираем только топ-3 товары по продажам
ORDER BY date_, shop_number, rnk


-- Часть 2. Задание 4.

WITH sales_with_prev AS (
    SELECT s.date AS date_,                             
        s.shop_number,                               
        g.category,                                  
        SUM(s.quantity * g.price) AS total_sales,      -- сумма продаж
        LAG(s.date) OVER (PARTITION BY s.shop_number, g.category ORDER BY s.date) AS prev_date -- используем оконную функцию LAG(s.date) для нахождения предыдущей даты по каждому магазину и категории
    FROM  sales s
    JOIN shops sh ON s.shop_number = sh.shop_number    
    JOIN goods g ON s.good_id = g.good_id             
    WHERE sh.city = 'СПб'         -- условие для магазинов в Санкт-Петербурге        
    GROUP BY s.date, s.shop_number, g.category            
)
SELECT t1.date_ AS date_,                               
    t1.shop_number,                                 
    t1.category,                                     
    t2.total_sales AS prev_sales                    
FROM sales_with_prev t1
LEFT JOIN sales_with_prev t2 -- объединяем таблицу sales_with_prev саму с собой
ON t1.shop_number = t2.shop_number AND            
    t1.category = t2.category AND                    
    t1.prev_date = t2.date_                          
ORDER BY t1.date_, t1.shop_number, t1.category;  


-- Часть 3.

-- создание таблицы
CREATE TABLE query (
    searchid INT PRIMARY KEY,   -- id запроса
    year INT,                   -- год
    month INT,                  -- месяц
    day INT,                    -- день
    userid INT,                 -- id пользователя
    ts INT,                     -- время запроса в формате UNIX
    devicetype VARCHAR(50),     -- тип устройства (например, mobile, desktop)
    deviceid VARCHAR(50),       -- id устройства
    query VARCHAR(255)          -- поисковой запрос
)

-- заполнение данными

INSERT INTO query (searchid, year, month, day, userid, ts, devicetype, deviceid, query) VALUES
(1, 2023, 10, 1, 101, 1633084800, 'mobile', 'dev1', 'к'),
(2, 2023, 10, 1, 101, 1633084860, 'mobile', 'dev1', 'ку'),
(3, 2023, 10, 1, 101, 1633084920, 'mobile', 'dev1', 'куп'),
(4, 2023, 10, 1, 101, 1633084980, 'mobile', 'dev1', 'купить'),
(5, 2023, 10, 1, 101, 1633085040, 'mobile', 'dev1', 'купить кур'),
(6, 2023, 10, 1, 101, 1633085100, 'mobile', 'dev1', 'купить курт'),
(7, 2023, 10, 1, 101, 1633085160, 'mobile', 'dev1', 'купить куртку'),
(8, 2023, 10, 2, 102, 1633171200, 'desktop', 'dev2', 'планшет'),
(9, 2023, 10, 2, 102, 1633171260, 'desktop', 'dev2', 'купить планшет'),
(10, 2023, 10, 2, 103, 1633171320, 'desktop', 'dev3', 'телефон'),
(11, 2023, 10, 3, 104, 1633257600, 'mobile', 'dev4', 'ноутбук'),
(12, 2023, 10, 3, 104, 1633257660, 'mobile', 'dev4', 'купить ноутбук'),
(13, 2023, 10, 4, 105, 1633344000, 'mobile', 'dev5', 'игра'),
(14, 2023, 10, 4, 105, 1633344060, 'mobile', 'dev5', 'купить игру'),
(15, 2023, 10, 5, 106, 1633430400, 'desktop', 'dev6', 'наушники'),
(16, 2023, 10, 5, 106, 1633430460, 'desktop', 'dev6', 'купить наушники'),
(17, 2023, 10, 6, 107, 1633516800, 'mobile', 'dev7', 'мышка'),
(18, 2023, 10, 6, 107, 1633516860, 'mobile', 'dev7', 'купить мышку'),
(19, 2023, 10, 7, 108, 1633603200, 'desktop', 'dev8', 'сумка'),
(20, 2023, 10, 7, 108, 1633603260, 'desktop', 'dev8', 'купить сумку')



-- для каждого запроса определим значение is_final:
WITH query_with_next AS (
    SELECT q.searchid,
        q.userid,
        q.deviceid,
        to_timestamp(q.ts) AS ts,  -- преобразуем время в читаемый формат
        q.query,
        LEAD(q.ts) OVER (PARTITION BY q.userid, q.deviceid ORDER BY q.ts) AS next_ts_unix,  -- следующий запрос (UNIX-время)
        LEAD(q.query) OVER (PARTITION BY q.userid, q.deviceid ORDER BY q.ts) AS next_query  -- следующий запрос
    FROM query q
)
SELECT q.searchid,
    q.userid,
    q.deviceid,
    q.ts,
    to_timestamp(q.next_ts_unix) AS next_ts, -- преобразуем время следующего запроса
    q.query,
    CASE
        -- условие для is_final = 1: Нет следующего запроса или время между запросами > 3 минут
        WHEN (q.next_ts_unix IS NULL) OR (q.next_ts_unix - extract(epoch FROM q.ts) > 180) THEN 1
        -- условие для is_final = 2: Следующий запрос короче, и время между запросами > 1 минута
        WHEN LENGTH(q.next_query) < LENGTH(q.query) AND (q.next_ts_unix - extract(epoch FROM q.ts) > 60) THEN 2
        -- иначе is_final = 0
        ELSE 0
    END AS is_final
FROM query_with_next q
ORDER BY q.ts;

-- выведем детальные данные о времени и там, где is_final = 1 
WITH query_with_next AS (
    SELECT q.searchid,
        q.year,
        q.month,
        q.day,
        q.userid,
        q.deviceid,
        q.devicetype,
        to_timestamp(q.ts) AS ts, 
        q.query,
        LEAD(q.ts) OVER (PARTITION BY q.userid, q.deviceid ORDER BY q.ts) AS next_ts_unix,  
        LEAD(q.query) OVER (PARTITION BY q.userid, q.deviceid ORDER BY q.ts) AS next_query 
    FROM query q
)
SELECT q.year,            -- год запроса
    q.month,           -- месяц запроса
    q.day,             -- день запроса
    q.userid,          -- id пользователя
    q.ts,              -- время текущего запроса
    q.devicetype,      -- тип устройства
    q.deviceid,        -- id устройства
    q.query,           -- текущий запрос
    q.next_query,      -- следующий запрос
    CASE
        -- условие для is_final = 1: Нет следующего запроса или время между запросами > 3 минут
        WHEN (q.next_ts_unix IS NULL) OR (q.next_ts_unix - extract(epoch FROM q.ts) > 180) THEN 1
        -- условие для is_final = 2: Следующий запрос короче, и время между запросами > 1 минута
        WHEN LENGTH(q.next_query) < LENGTH(q.query) AND (q.next_ts_unix - extract(epoch FROM q.ts) > 60) THEN 2
        -- иначе is_final = 0
        ELSE 0
    END AS is_final
FROM query_with_next q
WHERE 
    -- фильтруем только записи с is_final = 1
    (CASE
        WHEN (q.next_ts_unix IS NULL) OR (q.next_ts_unix - extract(epoch FROM q.ts) > 180) THEN 1
        WHEN LENGTH(q.next_query) < LENGTH(q.query) AND (q.next_ts_unix - extract(epoch FROM q.ts) > 60) THEN 2
        ELSE 0
    END) = 1
ORDER BY q.ts;



