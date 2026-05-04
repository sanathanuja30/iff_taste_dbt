-- gold/dim_date.sql
-- Date dimension spanning the range of transaction dates in the dataset.
-- Provides year, quarter, month, and week attributes for time-based filters.

WITH date_spine AS (
    SELECT
        UNNEST(
            GENERATE_SERIES(
                (SELECT MIN(transaction_date) FROM {{ ref('slv_sales_transactions') }}),
                (SELECT MAX(transaction_date) FROM {{ ref('slv_sales_transactions') }}),
                INTERVAL '1 day'
            )
        )::DATE AS date_day
)
SELECT
    date_day                                        AS date_key,
    date_day,
    YEAR(date_day)                                  AS year,
    QUARTER(date_day)                               AS quarter,
    MONTH(date_day)                                 AS month,
    MONTHNAME(date_day)                             AS month_name,
    WEEK(date_day)                                  AS week_of_year,
    DAYOFWEEK(date_day)                             AS day_of_week,
    DAYNAME(date_day)                               AS day_name,
    -- Convenience label for quarter-based filters (e.g. "2023-Q3")
    CONCAT(YEAR(date_day), '-Q', QUARTER(date_day)) AS year_quarter_label
FROM date_spine
