-- =============================================================================
-- Фінальний проєкт GoIT «Relational Databases» — схема pandemic
-- Той самий SQL, що й у final_project.ipynb, одним файлом.
--
-- Запуск (PostgreSQL 16+, з каталогу репозиторію, щоб \copy знайшов CSV):
--     psql -d <база> -v ON_ERROR_STOP=1 -f solution.sql
--
-- Файл використовує \copy (клієнтський, виконується psql), тому права на
-- серверну файлову систему не потрібні. Якщо CSV лежить в іншому місці —
-- виправте шлях у рядку \copy нижче.
--
-- Потрібна версія PostgreSQL 16+ через pg_input_is_valid() у профілюванні
-- даних (завдання 1) і в порівнянні способів відбору числових значень
-- (завдання 5). Решта коду працює починаючи з PostgreSQL 12.
-- =============================================================================


-- =============================================================================
-- Завдання 1. Схема та завантаження даних
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS pandemic;
SET search_path TO pandemic;

DROP TABLE IF EXISTS pandemic.disease_cases;
DROP TABLE IF EXISTS pandemic.entities;
DROP TABLE IF EXISTS pandemic.infectious_cases;

-- Staging-таблиця: усі колонки TEXT, дані завантажуються «як є».
-- Типізація — крок нормалізації (завдання 2), а нетипізована копія
-- потрібна для перевірки «значення є числовим» у завданні 5.
CREATE TABLE pandemic.infectious_cases (
    entity                TEXT,
    code                  TEXT,
    year                  TEXT,
    number_yaws           TEXT,
    polio_cases           TEXT,
    cases_guinea_worm     TEXT,
    number_rabies         TEXT,
    number_malaria        TEXT,
    number_hiv            TEXT,
    number_tuberculosis   TEXT,
    number_smallpox       TEXT,
    number_cholera_cases  TEXT
);

-- У форматі CSV порожнє нелапковане поле COPY вважає NULL,
-- тому пропуски в даних одразу стають NULL, а не порожніми рядками.
\copy pandemic.infectious_cases (entity, code, year, number_yaws, polio_cases, cases_guinea_worm, number_rabies, number_malaria, number_hiv, number_tuberculosis, number_smallpox, number_cholera_cases) FROM 'infectious_cases.csv' WITH (FORMAT CSV, HEADER true)

-- Перегляд даних
SELECT * FROM pandemic.infectious_cases LIMIT 10;

-- Профіль показників: заповненість, нечислові значення, дробові значення.
-- pg_input_is_valid() перевіряє значення справжнім парсером типу numeric
-- і не падає на некоректному вводі (PostgreSQL 16+).
SELECT
    measure.name                                                         AS column_name,
    COUNT(*) FILTER (WHERE measure.value IS NOT NULL)                    AS filled,
    ROUND(100.0 * COUNT(*) FILTER (WHERE measure.value IS NOT NULL) / COUNT(*), 1) AS filled_pct,
    COUNT(*) FILTER (WHERE measure.value IS NOT NULL
                       AND NOT pg_input_is_valid(measure.value, 'numeric')) AS non_numeric,
    COUNT(*) FILTER (WHERE measure.value LIKE '%.%')                     AS fractional
FROM pandemic.infectious_cases AS ic
CROSS JOIN LATERAL (
    VALUES ('number_yaws',          ic.number_yaws),
           ('polio_cases',          ic.polio_cases),
           ('cases_guinea_worm',    ic.cases_guinea_worm),
           ('number_rabies',        ic.number_rabies),
           ('number_malaria',       ic.number_malaria),
           ('number_hiv',           ic.number_hiv),
           ('number_tuberculosis',  ic.number_tuberculosis),
           ('number_smallpox',      ic.number_smallpox),
           ('number_cholera_cases', ic.number_cholera_cases)
) AS measure(name, value)
GROUP BY measure.name
ORDER BY filled DESC;

-- Ключ, діапазон років і кількість сутностей без ISO-коду
SELECT
    COUNT(*)                                           AS n_rows,
    COUNT(DISTINCT entity)                             AS n_entities,
    COUNT(DISTINCT code)                               AS n_codes,
    COUNT(*) FILTER (WHERE code IS NULL)               AS rows_without_code,
    COUNT(DISTINCT entity) FILTER (WHERE code IS NULL) AS entities_without_code,
    MIN(year::INT)                                     AS first_year,
    MAX(year::INT)                                     AS last_year,
    COUNT(DISTINCT (entity, year))                     AS unique_entity_year
FROM pandemic.infectious_cases;


-- =============================================================================
-- Завдання 2. Нормалізація до 3-ї нормальної форми
--
-- Ключ початкової таблиці — (Entity, Year). Показники залежать від повного
-- ключа, а Code — лише від Entity, тобто частково від ключа (порушення 2НФ,
-- а отже й 3НФ). Виносимо Entity + Code в довідник entities, у таблиці
-- показників лишаємо entity_id.
-- =============================================================================

-- Перевірка функціональної залежності Entity -> Code: має бути 0 рядків
SELECT entity, COUNT(DISTINCT code) AS distinct_codes
FROM pandemic.infectious_cases
GROUP BY entity
HAVING COUNT(DISTINCT code) > 1;

-- Довідник сутностей. VARCHAR(8), бо крім ISO-3166 alpha-3 у даних є три
-- псевдокоди OWID (OWID_WRL, OWID_SRM, OWID_YGS); у 34 агрегатів коду немає.
CREATE TABLE pandemic.entities (
    entity_id  SERIAL       PRIMARY KEY,
    entity     TEXT         NOT NULL UNIQUE,
    code       VARCHAR(8)
);

-- Показники. NUMERIC, бо оцінки IHME дробові: INTEGER відкинув би дробову
-- частину, а DOUBLE PRECISION додав би похибку двійкового представлення.
CREATE TABLE pandemic.disease_cases (
    entity_id             INTEGER  NOT NULL REFERENCES pandemic.entities (entity_id),
    year                  SMALLINT NOT NULL,
    number_yaws           NUMERIC,
    polio_cases           NUMERIC,
    cases_guinea_worm     NUMERIC,
    number_rabies         NUMERIC,
    number_malaria        NUMERIC,
    number_hiv            NUMERIC,
    number_tuberculosis   NUMERIC,
    number_smallpox       NUMERIC,
    number_cholera_cases  NUMERIC,
    PRIMARY KEY (entity_id, year)
);

CREATE INDEX ix_disease_cases_year ON pandemic.disease_cases (year);

INSERT INTO pandemic.entities (entity, code)
SELECT DISTINCT TRIM(entity), NULLIF(TRIM(code), '')
FROM pandemic.infectious_cases
ORDER BY 1;

INSERT INTO pandemic.disease_cases (
    entity_id, year, number_yaws, polio_cases, cases_guinea_worm, number_rabies,
    number_malaria, number_hiv, number_tuberculosis, number_smallpox, number_cholera_cases
)
SELECT
    e.entity_id,
    ic.year::SMALLINT,
    ic.number_yaws::NUMERIC,
    ic.polio_cases::NUMERIC,
    ic.cases_guinea_worm::NUMERIC,
    ic.number_rabies::NUMERIC,
    ic.number_malaria::NUMERIC,
    ic.number_hiv::NUMERIC,
    ic.number_tuberculosis::NUMERIC,
    ic.number_smallpox::NUMERIC,
    ic.number_cholera_cases::NUMERIC
FROM pandemic.infectious_cases AS ic
JOIN pandemic.entities AS e ON e.entity = TRIM(ic.entity);

-- Контроль: кількість рядків, сутності без коду, «сироти»
SELECT
    (SELECT COUNT(*) FROM pandemic.infectious_cases)            AS staging_rows,
    (SELECT COUNT(*) FROM pandemic.entities)                    AS entities_rows,
    (SELECT COUNT(*) FROM pandemic.disease_cases)               AS disease_cases_rows,
    (SELECT COUNT(*) FROM pandemic.entities WHERE code IS NULL) AS entities_without_code,
    (SELECT COUNT(*) FROM pandemic.disease_cases d
       LEFT JOIN pandemic.entities e USING (entity_id)
      WHERE e.entity_id IS NULL)                                AS orphan_rows;

-- Контроль: типізація нічого не змінила (має бути 0).
-- IS DISTINCT FROM, а не <>: на NULL звичайне порівняння дало б NULL
-- і тихо пропустило б розбіжність.
SELECT COUNT(*) AS mismatched_rows
FROM pandemic.infectious_cases AS ic
JOIN pandemic.entities AS e      ON e.entity = TRIM(ic.entity)
JOIN pandemic.disease_cases AS d ON d.entity_id = e.entity_id
                                AND d.year = ic.year::SMALLINT
WHERE d.number_yaws          IS DISTINCT FROM ic.number_yaws::NUMERIC
   OR d.polio_cases          IS DISTINCT FROM ic.polio_cases::NUMERIC
   OR d.cases_guinea_worm    IS DISTINCT FROM ic.cases_guinea_worm::NUMERIC
   OR d.number_rabies        IS DISTINCT FROM ic.number_rabies::NUMERIC
   OR d.number_malaria       IS DISTINCT FROM ic.number_malaria::NUMERIC
   OR d.number_hiv           IS DISTINCT FROM ic.number_hiv::NUMERIC
   OR d.number_tuberculosis  IS DISTINCT FROM ic.number_tuberculosis::NUMERIC
   OR d.number_smallpox      IS DISTINCT FROM ic.number_smallpox::NUMERIC
   OR d.number_cholera_cases IS DISTINCT FROM ic.number_cholera_cases::NUMERIC;

-- Приклад вибірки з нормалізованих таблиць
SELECT e.entity, e.code, d.year,
       d.number_rabies, d.number_tuberculosis, d.number_hiv
FROM pandemic.disease_cases AS d
JOIN pandemic.entities AS e USING (entity_id)
WHERE e.code = 'UKR' AND d.year BETWEEN 2014 AND 2019
ORDER BY d.year;


-- =============================================================================
-- Завдання 3. Статистика по Number_rabies
--
-- HAVING COUNT(...) > 0 обов'язковий: у PostgreSQL ORDER BY ... DESC за
-- замовчуванням ставить NULL першими (DESC NULLS FIRST), тому 19 сутностей
-- без жодного спостереження інакше зайняли б усю першу десятку.
-- Альтернатива — ORDER BY avg_rabies DESC NULLS LAST.
-- =============================================================================

SELECT
    e.entity_id,
    e.entity,
    e.code,
    COUNT(d.number_rabies)          AS years_observed,
    ROUND(AVG(d.number_rabies), 4)  AS avg_rabies,
    ROUND(MIN(d.number_rabies), 4)  AS min_rabies,
    ROUND(MAX(d.number_rabies), 4)  AS max_rabies,
    ROUND(SUM(d.number_rabies), 4)  AS sum_rabies
FROM pandemic.disease_cases AS d
JOIN pandemic.entities AS e USING (entity_id)
GROUP BY e.entity_id, e.entity, e.code
HAVING COUNT(d.number_rabies) > 0
ORDER BY avg_rabies DESC
LIMIT 10;

-- Той самий рейтинг лише по країнах: агрегати відкидаємо по відсутньому
-- ISO-коду та по псевдокодах OWID
SELECT
    e.entity,
    e.code,
    COUNT(d.number_rabies)          AS years_observed,
    ROUND(AVG(d.number_rabies), 4)  AS avg_rabies,
    ROUND(MIN(d.number_rabies), 4)  AS min_rabies,
    ROUND(MAX(d.number_rabies), 4)  AS max_rabies,
    ROUND(SUM(d.number_rabies), 4)  AS sum_rabies
FROM pandemic.disease_cases AS d
JOIN pandemic.entities AS e USING (entity_id)
WHERE e.code IS NOT NULL AND e.code NOT LIKE 'OWID%'
GROUP BY e.entity_id, e.entity, e.code
HAVING COUNT(d.number_rabies) > 0
ORDER BY avg_rabies DESC
LIMIT 10;


-- =============================================================================
-- Завдання 4. Різниця в роках вбудованими функціями
--
-- MAKE_DATE(year, 1, 1)             — 1 січня відповідного року;
-- CURRENT_DATE                      — поточна дата;
-- EXTRACT(YEAR FROM AGE(...))       — різниця в повних роках.
-- years_diff_calendar — для порівняння: різниця календарних років.
-- Для 1 січня значення збігаються; для довільної дати AGE дає повні роки.
-- =============================================================================

SELECT
    e.entity,
    d.year,
    MAKE_DATE(d.year::INT, 1, 1)                                             AS year_start,
    CURRENT_DATE                                                             AS today,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, MAKE_DATE(d.year::INT, 1, 1)))::INT  AS years_diff,
    (DATE_PART('year', CURRENT_DATE) - d.year)::INT                          AS years_diff_calendar,
    AGE(CURRENT_DATE, MAKE_DATE(d.year::INT, 1, 1))::TEXT                    AS full_age_interval
FROM pandemic.disease_cases AS d
JOIN pandemic.entities AS e USING (entity_id)
WHERE e.code = 'UKR'
ORDER BY d.year DESC
LIMIT 10;

-- Де дві семантики розходяться
SELECT
    sample.label,
    sample.event_date,
    CURRENT_DATE                                                 AS today,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, sample.event_date))::INT AS years_diff_age,
    (DATE_PART('year', CURRENT_DATE) - DATE_PART('year', sample.event_date))::INT
                                                                 AS years_diff_calendar
FROM (VALUES ('1 січня 1996',   DATE '1996-01-01'),
             ('1 липня 1996',   DATE '1996-07-01'),
             ('31 грудня 1996', DATE '1996-12-31')) AS sample(label, event_date);


-- =============================================================================
-- Завдання 5. Власні функції
-- =============================================================================

-- STABLE, а не IMMUTABLE: результат залежить від CURRENT_DATE, тож незмінним
-- у часі не є, але в межах одного запиту стабільний.
CREATE OR REPLACE FUNCTION pandemic.years_since_year(p_year INTEGER)
RETURNS INTEGER
LANGUAGE sql
STABLE
RETURNS NULL ON NULL INPUT
AS $$
    SELECT EXTRACT(YEAR FROM AGE(CURRENT_DATE, MAKE_DATE(p_year, 1, 1)))::INTEGER;
$$;

COMMENT ON FUNCTION pandemic.years_since_year(INTEGER) IS
    'Різниця в повних роках між CURRENT_DATE і 1 січня вказаного року';

-- IMMUTABLE: на однакових аргументах результат завжди однаковий.
-- Нульовий або NULL дільник дає NULL, а не division_by_zero.
CREATE OR REPLACE FUNCTION pandemic.avg_cases_per_period(
    p_cases   NUMERIC,
    p_divisor NUMERIC
)
RETURNS NUMERIC
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
    IF p_cases IS NULL OR p_divisor IS NULL OR p_divisor = 0 THEN
        RETURN NULL;
    END IF;

    RETURN ROUND(p_cases / p_divisor, 2);
END;
$$;

COMMENT ON FUNCTION pandemic.avg_cases_per_period(NUMERIC, NUMERIC) IS
    'Середня кількість захворювань за період: річна кількість / дільник (12, 4, 2 ...)';

-- Перевірка на прикладі з умови: 1996 -> 1996-01-01 -> різниця в роках,
-- і всі три дільники: 12 (місяць), 4 (квартал), 2 (півріччя)
SELECT
    1996                                    AS year_in,
    MAKE_DATE(1996, 1, 1)                   AS year_start,
    CURRENT_DATE                            AS today,
    pandemic.years_since_year(1996)         AS years_since_year,
    pandemic.years_since_year(NULL)         AS null_input,
    pandemic.avg_cases_per_period(1200, 12) AS per_month,
    pandemic.avg_cases_per_period(1200, 4)  AS per_quarter,
    pandemic.avg_cases_per_period(1200, 2)  AS per_half_year,
    pandemic.avg_cases_per_period(1200, 0)  AS divisor_zero,
    pandemic.avg_cases_per_period(NULL, 12) AS cases_null;

-- Обидві функції на нормалізованій таблиці.
-- «Лише числові значення» тут — це IS NOT NULL: у колонці NUMERIC
-- нечислового значення бути не може.
SELECT
    e.entity,
    e.code,
    d.year,
    pandemic.years_since_year(d.year::INT)              AS years_since_year,
    d.number_rabies                                     AS cases_per_year,
    pandemic.avg_cases_per_period(d.number_rabies, 12)  AS avg_per_month,
    pandemic.avg_cases_per_period(d.number_rabies, 4)   AS avg_per_quarter,
    pandemic.avg_cases_per_period(d.number_rabies, 2)   AS avg_per_half_year
FROM pandemic.disease_cases AS d
JOIN pandemic.entities AS e USING (entity_id)
WHERE d.number_rabies IS NOT NULL
ORDER BY d.number_rabies DESC
LIMIT 10;

-- Ті самі функції на staging-таблиці, де number_rabies — TEXT.
-- Ось тут фільтр «значення є числовим» справді потрібен: без нього
-- приведення ::NUMERIC впало б на першому ж нечисловому значенні.
SELECT
    ic.entity,
    ic.year::INT                                                 AS year,
    pandemic.years_since_year(ic.year::INT)                      AS years_since_year,
    ic.number_rabies::NUMERIC                                    AS cases_per_year,
    pandemic.avg_cases_per_period(ic.number_rabies::NUMERIC, 12) AS avg_per_month,
    pandemic.avg_cases_per_period(ic.number_rabies::NUMERIC, 4)  AS avg_per_quarter,
    pandemic.avg_cases_per_period(ic.number_rabies::NUMERIC, 2)  AS avg_per_half_year
FROM pandemic.infectious_cases AS ic
WHERE ic.number_rabies ~ '^-?[0-9]+(\.[0-9]+)?([eE][-+]?[0-9]+)?$'
ORDER BY ic.number_rabies::NUMERIC DESC
LIMIT 10;

-- Три способи відбору числових значень дають однакову кількість рядків
SELECT
    (SELECT COUNT(*) FROM pandemic.infectious_cases
      WHERE number_rabies ~ '^-?[0-9]+(\.[0-9]+)?([eE][-+]?[0-9]+)?$')           AS numeric_by_regex,
    (SELECT COUNT(*) FROM pandemic.infectious_cases
      WHERE number_rabies IS NOT NULL
        AND pg_input_is_valid(number_rabies, 'numeric'))                         AS numeric_by_parser,
    (SELECT COUNT(*) FROM pandemic.disease_cases WHERE number_rabies IS NOT NULL) AS numeric_in_typed_table,
    (SELECT COUNT(*) FROM pandemic.infectious_cases WHERE number_rabies IS NULL)  AS empty_values;
