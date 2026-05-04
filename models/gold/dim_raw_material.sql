-- gold/dim_raw_material.sql
-- Raw material dimension.

SELECT
    raw_material_id                                 AS raw_material_key,
    raw_material_id,
    raw_material_name
FROM {{ ref('slv_raw_materials') }}
