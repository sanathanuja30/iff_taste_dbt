-- bronze/brz_raw_materials.sql
-- Raw ingestion of raw_materials seed data.

SELECT
    raw_material_id::INTEGER                                AS raw_material_id,
    TRIM(name)                                              AS raw_material_name,
    TRY_STRPTIME(generation_date, '%m/%d/%y')::DATE         AS generation_date,
    batch_number::INTEGER                                   AS batch_number
FROM {{ ref('raw_materials') }}
