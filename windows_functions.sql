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




