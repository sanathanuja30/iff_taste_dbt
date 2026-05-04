-- silver/slv_providers.sql
-- Cleaned providers. Deduplication: highest batch_number wins.

WITH normalised AS (
    SELECT
        provider_id,
        provider_name,
        location_city,
        {{ title_case('location_country') }}        AS location_country,
        batch_number
    FROM {{ ref('brz_providers') }}
),
ranked AS (
    SELECT
        n.provider_id,
        n.provider_name,
        n.location_city,
        n.location_country,
        n.batch_number,
        b.generation_date,
        ROW_NUMBER() OVER (PARTITION BY n.provider_id ORDER BY n.batch_number DESC) AS rn
    FROM normalised n
    JOIN {{ ref('brz_providers') }} b
        ON b.provider_id = n.provider_id AND b.batch_number = n.batch_number
)
SELECT
    provider_id,
    provider_name,
    location_city,
    location_country,
    generation_date,
    batch_number
FROM ranked
WHERE rn = 1
