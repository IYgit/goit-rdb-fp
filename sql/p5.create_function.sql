DELIMITER $$

CREATE FUNCTION year_difference(input_year YEAR)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE first_january_date DATE;
    DECLARE years_diff INT;

    -- Формуємо дату першого січня відповідного року
    SET first_january_date = CONCAT(input_year, '-01-01');
    
    -- Обчислюємо різницю в роках між поточною датою та датою першого січня
    SET years_diff = TIMESTAMPDIFF(YEAR, first_january_date, CURDATE());
    
    RETURN years_diff;
END $$

DELIMITER ;
