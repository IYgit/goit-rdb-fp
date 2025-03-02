use pandemic;

SELECT 
    ic.Year,
    -- Створюємо атрибут, що містить дату першого січня відповідного року
    CONCAT(ic.Year, '-01-01') AS first_january_date,
    
    -- Створюємо атрибут, що дорівнює поточній даті
    CURDATE() AS current_date_value,
    
    -- Створюємо атрибут, що обчислює різницю в роках між поточною датою і датою першого січня
    TIMESTAMPDIFF(YEAR, CONCAT(ic.Year, '-01-01'), CURDATE()) AS year_difference
FROM 
    infectious_cases ic;

