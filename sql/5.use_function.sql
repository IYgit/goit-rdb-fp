use pandemic;

SELECT 
    ic.Year,
    -- Викликаємо функцію для обчислення різниці в роках
    year_difference(ic.Year) AS year_difference
FROM 
    infectious_cases ic;
