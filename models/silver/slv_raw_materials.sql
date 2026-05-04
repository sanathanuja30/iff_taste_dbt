-- silver/slv_raw_materials.sql
-- Cleaned raw materials. Deduplication: highest batch_number wins.

WITH ranked AS (
    SELECT
        raw_material_id,
        raw_material_name,
        generation_date,
        batch_number,
        ROW_NUMBER() OVER (PARTITION BY raw_material_id ORDER BY batch_number DESC) AS rn
    FROM {{ ref('brz_raw_materials') }}
)
SELECT
    raw_material_id,
    raw_material_name,
    generation_date,
    batch_number
FROM ranked
WHERE rn = 1
