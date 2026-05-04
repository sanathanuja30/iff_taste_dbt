-- silver/slv_recipes.sql
-- Cleaned recipes. Deduplication: highest batch_number wins.

WITH ranked AS (
    SELECT
        recipe_id,
        raw_material_id,
        raw_material_ratio,
        flavour_id,
        flavour_ratio,
        ingredient_id,
        ingredient_ratio,
        heat_process,
        yield_pct,
        generation_date,
        batch_number,
        ROW_NUMBER() OVER (PARTITION BY recipe_id ORDER BY batch_number DESC) AS rn
    FROM {{ ref('brz_recipes') }}
)
SELECT
    recipe_id,
    raw_material_id,
    raw_material_ratio,
    flavour_id,
    flavour_ratio,
    ingredient_id,
    ingredient_ratio,
    heat_process,
    heat_process IS NOT NULL                        AS has_heat_process,
    yield_pct,
    generation_date,
    batch_number
FROM ranked
WHERE rn = 1
