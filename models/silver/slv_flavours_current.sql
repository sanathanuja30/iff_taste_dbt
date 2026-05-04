-- silver/slv_flavours_current.sql
-- Current snapshot of flavours – the latest batch's description per flavour.
-- Used as the source for dim_flavour and for FK validation in facts.
--
-- NOTE: This is a simple deduplication (highest batch_number wins), independent of
-- the SCD2 history in slv_flavours_history. We keep them separate because:
--   - slv_flavours_history tracks all *changed* descriptions (for the Description Tracker)
--   - slv_flavours_current always has exactly one row per flavour_id (for FK integrity)

WITH ranked AS (
    SELECT
        flavour_id,
        flavour_name,
        description,
        generation_date,
        batch_number,
        ROW_NUMBER() OVER (PARTITION BY flavour_id ORDER BY batch_number DESC) AS rn
    FROM {{ ref('brz_flavours') }}
)
SELECT
    flavour_id,
    flavour_name,
    description,
    generation_date AS valid_from,
    batch_number
FROM ranked
WHERE rn = 1
