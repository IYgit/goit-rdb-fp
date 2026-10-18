# Скриншоти

Папка для скриншотів, яких вимагає умова фінального проєкту («скриншоти створених таблиць,
запитів і результатів»). Основний доказ виконання — сам
[`final_project.ipynb`](../final_project.ipynb) зі збереженими output-ами всіх клітинок;
скриншоти додаються як ілюстрація.

Що зняти після `Runtime → Restart session and run all` у Colab:

| Файл | Що має бути на кадрі |
|---|---|
| `01_schema_and_tables.png` | клітинка `CREATE SCHEMA pandemic` + результат запиту `SELECT * FROM pandemic.infectious_cases LIMIT 10` |
| `02_profile.png` | профіль показників (заповненість, `non_numeric`, `fractional`) і рядок зі статистикою по `Entity` / `Code` / `Year` |
| `03_normalized_tables.png` | DDL `entities` + `disease_cases` і контрольний запит (`staging_rows`, `entities_rows`, `disease_cases_rows`, `orphan_rows`) |
| `04_task3_top10.png` | завдання 3: топ-10 за середнім `Number_rabies` |
| `05_task4_years_diff.png` | завдання 4: колонки `year_start`, `today`, `years_diff` |
| `06_task5_functions.png` | завдання 5: `CREATE FUNCTION` обох функцій і запит із дільниками 12 / 4 / 2 |
| `07_final_checks.png` | фінальна клітинка з `assert`-ами та її вивід |

Файли можна називати інакше — важливо, щоб на кадрах були видні і запит, і його результат.
