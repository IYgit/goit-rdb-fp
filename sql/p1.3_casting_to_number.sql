use pandemic;

-- вимикаємо безпечний режим
SET SQL_SAFE_UPDATES = 0;
-------------------------------
UPDATE infectious_cases
SET Number_yaws = NULLIF(Number_yaws, '')
WHERE Number_yaws IS NOT NULL;

ALTER TABLE infectious_cases
MODIFY COLUMN Number_yaws INT;
---------------------------------
UPDATE infectious_cases
SET polio_cases = NULLIF(polio_cases, '')
WHERE polio_cases IS NOT NULL;

ALTER TABLE infectious_cases
MODIFY COLUMN polio_cases INT;
---------------------------------
UPDATE infectious_cases
SET cases_guinea_worm = NULLIF(cases_guinea_worm, '')
WHERE cases_guinea_worm IS NOT NULL;

ALTER TABLE infectious_cases
MODIFY COLUMN cases_guinea_worm INT;

---------------------------------
UPDATE infectious_cases
SET Number_smallpox = NULLIF(Number_smallpox, '')
WHERE Number_smallpox IS NOT NULL;

ALTER TABLE infectious_cases
MODIFY COLUMN Number_smallpox INT;

---------------------------------
UPDATE infectious_cases
SET Number_cholera_cases = NULLIF(Number_cholera_cases, '')
WHERE Number_cholera_cases IS NOT NULL;

ALTER TABLE infectious_cases
MODIFY COLUMN Number_cholera_cases INT;

---------------------------------
UPDATE infectious_cases
SET Number_rabies = NULLIF(Number_rabies, '')
WHERE Number_rabies IS NOT NULL;

ALTER TABLE infectious_cases
MODIFY COLUMN Number_rabies FLOAT;

---------------------------------
UPDATE infectious_cases
SET Number_malaria = NULLIF(Number_rabies, '')
WHERE Number_malaria IS NOT NULL;

ALTER TABLE infectious_cases
MODIFY COLUMN Number_malaria FLOAT;

---------------------------------
UPDATE infectious_cases
SET Number_hiv = NULLIF(Number_rabies, '')
WHERE Number_hiv IS NOT NULL;

ALTER TABLE infectious_cases
MODIFY COLUMN Number_hiv FLOAT;

---------------------------------
UPDATE infectious_cases
SET Number_tuberculosis = NULLIF(Number_rabies, '')
WHERE Number_tuberculosis IS NOT NULL;

ALTER TABLE infectious_cases
MODIFY COLUMN Number_tuberculosis FLOAT;

---------------------------------
UPDATE infectious_cases
SET Year = NULLIF(Year, '')
WHERE Year IS NOT NULL;

ALTER TABLE infectious_cases
MODIFY COLUMN Year YEAR;

---------------------------------

-- вимикаємо безпечний режим
SET SQL_SAFE_UPDATES = 1;
