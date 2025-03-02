use pandemic;

SET SQL_SAFE_UPDATES = 0;

-- Створення таблиці країн
CREATE TABLE countries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    entity VARCHAR(255) NOT NULL UNIQUE,
    code VARCHAR(255) NOT NULL UNIQUE
);

-- Заповнюємо Code, там де він відсутній
UPDATE infectious_cases
SET Code = Entity
WHERE Code = '';

-- Заповнення таблиці країн з таблиці infectious_cases
INSERT INTO countries (entity, code)
SELECT DISTINCT Entity, Code
FROM infectious_cases;

-- Додавання country_id як зовнішнього ключа
ALTER TABLE infectious_cases
ADD COLUMN country_id INT,
ADD FOREIGN KEY (country_id) REFERENCES countries(id) ON DELETE CASCADE;

-- Заповнення country_id
UPDATE infectious_cases ic
JOIN countries c ON ic.Entity = c.entity AND ic.Code = c.code
SET ic.country_id = c.id;

-- Видалення стовпців Entity і Code з infectious_cases
ALTER TABLE infectious_cases
DROP COLUMN Entity,
DROP COLUMN Code;

SET SQL_SAFE_UPDATES = 1;