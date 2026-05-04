-- silver/slv_customers.sql
-- Cleaned customers. Deduplication: highest batch_number per customer_id wins.
-- Country normalised to Title Case.
-- Note: title_case (list_transform lambda) is applied before the window function
-- to work around a DuckDB 1.5 type-binding bug with DATE columns + lambdas in CTEs.

WITH normalised AS (
    SELECT
        customer_id,
        customer_name,
        location_city,
        {{ title_case('location_country') }}        AS location_country,
        batch_number
    FROM {{ ref('brz_customers') }}
),
ranked AS (
    SELECT
        n.customer_id,
        n.customer_name,
        n.location_city,
        n.location_country,
        n.batch_number,
        b.generation_date,
        ROW_NUMBER() OVER (PARTITION BY n.customer_id ORDER BY n.batch_number DESC) AS rn
    FROM normalised n
    JOIN {{ ref('brz_customers') }} b
        ON b.customer_id = n.customer_id AND b.batch_number = n.batch_number
)
SELECT
    customer_id,
    customer_name,
    location_city,
    location_country,
    generation_date,
    batch_number
FROM ranked
WHERE rn = 1
