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

