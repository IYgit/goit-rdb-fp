# Фінальний проєкт — схема `pandemic`, нормалізація та аналітика `infectious_cases`

Фінальний проєкт курсу GoIT «Relational Databases». Робота виконана в Colab-сумісному
ноутбуці [`final_project.ipynb`](final_project.ipynb) і збережена разом з output-ами всіх
клітинок. PostgreSQL 16.2 піднімається всередині ноутбука через
[`pgserver`](https://pypi.org/project/pgserver/), тому ніяких зовнішніх сервісів, портів чи
креденшелів не потрібно.

Той самий SQL одним файлом — [`solution.sql`](solution.sql) (перевірений окремим запуском
`psql -f` проти чистої бази).

## Файли

| Файл | Призначення |
|---|---|
| [`final_project.ipynb`](final_project.ipynb) | основний deliverable: SQL + коментарі + збережені результати |
| [`solution.sql`](solution.sql) | весь SQL проєкту одним файлом, виконується через `psql` |
| [`infectious_cases.csv`](infectious_cases.csv) | вхідні дані (10 521 рядок, 528 КБ) |
| [`screenshots/`](screenshots/) | 23 скриншоти виконання в Colab (таблиці, запити, результати) з описом кожного кадру |
| [`task.md`](task.md) | умова завдання |

## Як запустити

### Google Colab

1. Відкрити `final_project.ipynb` у Colab (`File → Upload notebook` або прямо з GitHub).
2. `Runtime → Restart session and run all`.

Ноутбук сам знайде дані. Клітинка пошуку CSV пробує стратегії по порядку й друкує, яка
спрацювала:

1. **локальні шляхи** — каталог ноутбука, `/content`, `/content/data`, змонтований
   Google Drive (`/content/drive/MyDrive`, `/content/drive/MyDrive/goit-rdb-fp`);
2. **`CSV_URL`** — raw-посилання на `infectious_cases.csv` у цьому репозиторії
   (`https://raw.githubusercontent.com/IYgit/goit-rdb-fp/main/infectious_cases.csv`),
   3 спроби з паузами. Працює після того, як репозиторій запушено й він публічний; якщо
   назва репозиторію чи гілка інші — виправте константу `CSV_URL` у тій самій клітинці;
3. **`files.upload()`** — інтерактивне завантаження файлу з комп'ютера (fallback на випадок,
   якщо репозиторій ще не опублікований або немає мережі);
4. якщо не спрацювало ніщо — `FileNotFoundError` з інструкцією, що зробити.

### Локально

```bash
python -m venv .venv
.venv\Scripts\activate            # Windows;  source .venv/bin/activate — Linux/macOS
pip install pgserver psycopg2-binary "sqlalchemy>=2.0" pandas jupysql tzdata jupyter
jupyter notebook final_project.ipynb
```

CSV уже лежить поряд із ноутбуком, тому спрацьовує перша стратегія пошуку. На Windows
ноутбук додатково докопіює файли часових поясів у `pgserver` (у його Windows-білді немає
`share/postgresql/timezone`) — функція `ensure_pg_timezone_files()`.

### Тільки SQL

```bash
psql -v ON_ERROR_STOP=1 -d <база> -f solution.sql
```

Запускати з каталогу репозиторію: `solution.sql` читає CSV клієнтським `\copy` за
відносним шляхом. Потрібен PostgreSQL 16+ через `pg_input_is_valid()` (решта коду працює
з PostgreSQL 12).

## Дані

| | |
|---|---|
| Файл | `infectious_cases.csv`, 10 521 рядок |
| Джерело | Our World in Data / IHME (статистика інфекційних захворювань по країнах і роках) |
| Колонки | `Entity`, `Code`, `Year` + 9 показників (`Number_rabies`, `Number_malaria`, `Number_hiv`, `Number_tuberculosis`, `polio_cases`, `cases_guinea_worm`, `Number_yaws`, `Number_smallpox`, `Number_cholera_cases`) |
| Сутності | 245 унікальних `Entity`: країни **і** агрегати (`World`, регіони WHO, групи Світового банку, `G20`, `OECD Countries`) |
| Роки | 1920–2023 |
| Ключ | `(Entity, Year)` — `COUNT(DISTINCT (entity, year)) = COUNT(*) = 10 521`, дублів немає |
| Пропуски | заповненість від 0.7 % (`Number_yaws`) до 80.1 % (`cases_guinea_worm`); `Number_rabies` — 6 780 значень |

Файл лежить у репозиторії (528 КБ), бо саме з нього ноутбук тягне дані в Colab.

## Що зроблено

| Завдання | Результат |
|---|---|
| **1. Завантаження** | `CREATE SCHEMA pandemic`, `SET search_path`, staging-таблиця `infectious_cases` з колонками `TEXT`, імпорт серверним `COPY ... FROM STDIN` (`psycopg2.copy_expert`), профілювання даних |
| **2. Нормалізація до 3НФ** | `pandemic.entities` (245 рядків: `entity_id`, `entity` UNIQUE, `code`) і `pandemic.disease_cases` (10 521 рядок: `entity_id` + `year` як PK, 9 показників `NUMERIC`, `FOREIGN KEY` на довідник) |
| **3. Аналітика** | `AVG` / `MIN` / `MAX` / `SUM` по `Number_rabies` для кожної сутності, сортування за середнім спаданням, `LIMIT 10` (+ варіант лише по країнах) |
| **4. Різниця в роках** | `MAKE_DATE(year, 1, 1)`, `CURRENT_DATE`, `EXTRACT(YEAR FROM AGE(...))` та довідкова колонка з різницею календарних років |
| **5. Власні функції** | `pandemic.years_since_year(year)` (`LANGUAGE sql`, `STABLE`) і `pandemic.avg_cases_per_period(cases, divisor)` (`plpgsql`, `IMMUTABLE`); використані в запитах з дільниками 12 / 4 / 2 — на типізованій таблиці та на staging із фільтром числових значень |

## Рішення, які варто пояснити

**Staging у `TEXT`, типізація — на етапі нормалізації.** `COPY` не падає на жодному
значенні; залишається «сире» джерело для порівняння з нормалізованими таблицями; і головне
— вимога завдання 5 «використовуйте лише записи, у яких значення є числовим» має сенс саме
на нетипізованих даних. Профілювання показало, що нечислових значень у файлі немає взагалі
— «нечислове» тут означає порожнє поле.

**`NUMERIC`, а не `INTEGER` чи `DOUBLE PRECISION`.** `Number_rabies`, `Number_hiv`,
`Number_tuberculosis`, `Number_malaria` — модельні оцінки IHME, тому дробові (мінімальне
значення по сказу — 0.000055). `INTEGER` відкинув би дробову частину, `DOUBLE PRECISION`
додав би похибку двійкового представлення.

**Чому саме така декомпозиція.** `Code` залежить лише від `Entity`, тобто частково від
ключа `(Entity, Year)` — це порушення 2НФ (а отже й 3НФ). Після виносу в довідник
транзитивних залежностей не залишилось. Дев'ять показників в одному рядку 3НФ **не**
порушують: усі залежать від повного ключа й не визначають один одного, тому «довгий»
формат `(entity_id, year, disease, value)` тут не потрібен.

**`VARCHAR(8)` для коду.** Крім ISO-3166 alpha-3 у даних є три псевдокоди OWID
(`OWID_WRL`, `OWID_SRM`, `OWID_YGS`), тому `CHAR(3)` не підійшов. У 34 агрегатів коду немає
взагалі — колонка `NULL`-able.

**`HAVING COUNT(number_rabies) > 0` у завданні 3 — не косметика.** У PostgreSQL
`ORDER BY ... DESC` за замовчуванням ставить `NULL` **першими**, тому 19 сутностей без
жодного спостереження по сказу інакше зайняли б усю першу десятку. Альтернатива —
`ORDER BY avg_rabies DESC NULLS LAST`.

**`AGE` проти віднімання років.** `EXTRACT(YEAR FROM AGE(...))` дає кількість **повних**
років, `DATE_PART('year', CURRENT_DATE) - year` — різницю календарних. Для 1 січня вони
збігаються, для довільної дати — ні (у ноутбуці є клітинка, яка це показує). У власній
функції використано `AGE`, бо вона коректна для будь-якої дати.

**`search_path` двічі.** Команда `SET search_path TO pandemic` з умови діє лише в межах
сесії, тому той самий `search_path` переданий у `connect_args` SQLAlchemy-engine: інакше
`COPY` через окреме з'єднання не побачив би схему.

## Перевірка

Остання клітинка ноутбука перевіряє `assert`-ами всі контрольні точки:

* схема `pandemic` існує, у staging — 10 521 рядок;
* `entities` — 245 рядків, `disease_cases` — 10 521, «сиріт» немає;
* типізація `TEXT → NUMERIC` нічого не змінила (порівняння кожного показника зі staging);
* завдання 3 повертає рівно 10 рядків, середнє спадає, `min ≤ avg ≤ max`,
  `avg × years_observed = sum`;
* `years_since_year(year)` збігається з вбудованим виразом на всіх 10 521 рядку;
* `avg_cases_per_period(1200, 12 / 4 / 2)` = `100.00` / `300.00` / `600.00`, нульовий і
  `NULL` дільник дають `NULL`;
* три способи відбору числових значень (regexp, `pg_input_is_valid`, `IS NOT NULL` на
  типізованій колонці) дають однакові 6 780 рядків.

Ноутбук проходить `Restart & Run All`: перед DDL — `DROP ... IF EXISTS`, перед `COPY` —
`TRUNCATE`, жодного `RANDOM()`. Між запусками змінюються лише колонки, похідні від
`CURRENT_DATE` (завдання 4 і 5) — цього вимагає умова.
