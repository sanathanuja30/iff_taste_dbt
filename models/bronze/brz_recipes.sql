-- bronze/brz_recipes.sql
-- Raw ingestion of recipes seed data.
-- heat_process may be null (no heat applied); preserved as-is.

SELECT
    TRIM(recipe_id)                                         AS recipe_id,
    raw_material_id::INTEGER                                AS raw_material_id,
    raw_material_ratio::DECIMAL(10,4)                       AS raw_material_ratio,
    flavour_id::INTEGER                                     AS flavour_id,
    flavour_ratio::DECIMAL(10,4)                            AS flavour_ratio,
    ingredient_id::INTEGER                                  AS ingredient_id,
    ingredient_ratio::DECIMAL(10,4)                         AS ingredient_ratio,
    NULLIF(TRIM(heat_process), '')                          AS heat_process,
    yield::DECIMAL(10,4)                                    AS yield_pct,
    TRY_STRPTIME(generation_date, '%m/%d/%y')::DATE         AS generation_date,
    batch_number::INTEGER                                   AS batch_number
FROM {{ ref('recipes') }}
