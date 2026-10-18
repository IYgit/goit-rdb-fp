# Скриншоти

Кадри з виконання [`final_project.ipynb`](../final_project.ipynb) у Google Colab: створені
таблиці, запити та їхні результати. Нумерація відповідає порядку клітинок у ноутбуці.

## Завдання 1 — схема та завантаження даних

| Файл | Що на кадрі |
|---|---|
| `01-task1-create-schema.png` | `CREATE SCHEMA IF NOT EXISTS pandemic` + `SET search_path TO pandemic` |
| `02-task1-staging-table-ddl.png` | DDL staging-таблиці `pandemic.infectious_cases` (усі колонки `TEXT`) |
| `03-task1-data-preview.png` | `SELECT * FROM pandemic.infectious_cases LIMIT 10` — перші рядки завантажених даних |
| `04-task1-column-profile-query.png` | запит-профіль показників: заповненість, `pg_input_is_valid`, дробові значення |
| `05-task1-column-profile-result.png` | результат профілю: 0 нечислових значень, заповненість від 0.7 % до 80.1 % |
| `06-task1-dataset-overview.png` | 10 521 рядок, 245 `Entity`, 211 кодів, 1 128 рядків без коду, 1920–2023, `(Entity, Year)` — ключ |

## Завдання 2 — нормалізація до 3НФ

| Файл | Що на кадрі |
|---|---|
| `07-task2-entity-code-dependency-check.png` | перевірка залежності `Entity → Code` — порожній результат |
| `08-task2-normalized-tables-ddl.png` | DDL `pandemic.entities` і `pandemic.disease_cases` (PK, FK, індекс) |
| `09-task2-insert-entities.png` | заповнення довідника — 245 рядків |
| `10-task2-insert-disease-cases.png` | заповнення таблиці показників — 10 521 рядок |
| `11-task2-row-counts-check.png` | контроль: 10 521 / 245 / 10 521, 34 сутності без коду, `orphan_rows = 0` |
| `12-task2-lossless-cast-check.png` | `mismatched_rows = 0` — типізація `TEXT → NUMERIC` без втрат |
| `13-task2-normalized-sample-ukraine.png` | вибірка з `JOIN` по `entity_id` (Україна, 2014–2019) |

## Завдання 3 — статистика по `Number_rabies`

| Файл | Що на кадрі |
|---|---|
| `14-task3-rabies-aggregates-query.png` | запит з `AVG` / `MIN` / `MAX` / `SUM`, `HAVING`, сортуванням за середнім і `LIMIT 10` |
| `15-task3-rabies-top10-result.png` | топ-10: `World` ≈ 20 192, далі агрегати WB/WHO, `India` — єдина країна в десятці |
| `16-task3-nulls-first-trap.png` | той самий запит без `HAVING`: `DESC NULLS FIRST` виводить сутності з `avg = NULL` |

## Завдання 4 — різниця в роках вбудованими функціями

| Файл | Що на кадрі |
|---|---|
| `17-task4-years-diff-result.png` | колонки `year_start`, `today`, `years_diff`, `years_diff_calendar`, `full_age_interval` |
| `18-task4-age-vs-calendar-years.png` | запит і результат порівняння `AGE` з різницею календарних років (1 січня / 1 липня / 31 грудня 1996) |

## Завдання 5 — власні функції

| Файл | Що на кадрі |
|---|---|
| `19-task5-function-years-since-year.png` | `CREATE OR REPLACE FUNCTION pandemic.years_since_year(...)` (`LANGUAGE sql`, `STABLE`) |
| `20-task5-function-avg-cases-per-period.png` | `CREATE OR REPLACE FUNCTION pandemic.avg_cases_per_period(...)` (`plpgsql`, `IMMUTABLE`) |
| `21-task5-functions-check-1996.png` | перевірка з умови: `1996 → 1996-01-01 → 30`; дільники 12 / 4 / 2 → 100.00 / 300.00 / 600.00; `NULL` і нульовий дільник → `NULL` |
| `22-task5-functions-on-staging-numeric-filter.png` | обидві функції в запиті по staging-таблиці з фільтром числових значень (regexp) |
| `23-task5-numeric-filter-comparison.png` | три способи відбору числових значень дають однакові 6 780 рядків, 3 741 порожнє |
