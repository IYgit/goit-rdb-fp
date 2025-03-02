use pandemic;

-- середнє, мінімальне, максимальне значення та сума для Number_rabies
SELECT 
    c.entity, 
    c.code, 
    AVG(ic.Number_rabies) AS avg_number_rabies, 
    MIN(ic.Number_rabies) AS min_number_rabies, 
    MAX(ic.Number_rabies) AS max_number_rabies, 
    SUM(ic.Number_rabies) AS sum_number_rabies
FROM 
    infectious_cases ic
JOIN 
    countries c ON ic.country_id = c.id
WHERE 
    ic.Number_rabies != '' AND ic.Number_rabies IS NOT NULL
GROUP BY 
    c.entity, c.code
ORDER BY 
    avg_number_rabies DESC
LIMIT 10;



