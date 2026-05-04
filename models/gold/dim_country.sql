-- gold/dim_country.sql
-- BONUS: Unified country dimension sourced from three datasets.
--
-- Challenge: country names arrive inconsistently across sources:
--   - providers/customers: Title Case  (e.g. "United Kingdom", "South Africa")
--   - sales_transactions:  ALL CAPS    (e.g. "INDIA", "GERMANY")
--                          → normalised to Title Case in slv_sales_transactions
--
-- This model de-duplicates the union of all country strings so the
-- analysts can filter by a single canonical country name.

WITH countries_union AS (
    SELECT DISTINCT location_country    AS country_name, 'provider'     AS source
    FROM {{ ref('slv_providers') }}
    WHERE location_country IS NOT NULL

    UNION

    SELECT DISTINCT location_country    AS country_name, 'customer'     AS source
    FROM {{ ref('slv_customers') }}
    WHERE location_country IS NOT NULL

    UNION

    SELECT DISTINCT transaction_country AS country_name, 'transaction'  AS source
    FROM {{ ref('slv_sales_transactions') }}
    WHERE transaction_country IS NOT NULL
),
distinct_countries AS (
    SELECT
        country_name,
        -- Aggregate all sources this country name appears in (for traceability)
        STRING_AGG(DISTINCT source, ', ' ORDER BY source) AS appears_in_sources
    FROM countries_union
    GROUP BY country_name
)
SELECT
    ROW_NUMBER() OVER (ORDER BY country_name)       AS country_key,
    country_name,
    appears_in_sources
FROM distinct_countries
