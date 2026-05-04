-- gold/fact_recipes.sql
-- Recipe fact table.
-- Grain: one row per recipe (each recipe uniquely combines raw_material + flavour + ingredient).
--
-- Foreign keys link to all relevant dimensions.
-- Ratios and yield_pct are the measures.

SELECT
    r.recipe_id,
    r.raw_material_id                               AS raw_material_key,
    rm.raw_material_name,
    r.flavour_id                                    AS flavour_key,
    f.flavour_name,
    r.ingredient_id                                 AS ingredient_key,
    i.ingredient_name,
    i.provider_id                                   AS provider_key,
    i.provider_name,
    i.provider_country,
    -- Measures
    r.raw_material_ratio,
    r.flavour_ratio,
    r.ingredient_ratio,
    r.heat_process,
    r.has_heat_process,
    r.yield_pct
FROM {{ ref('slv_recipes') }}       r
LEFT JOIN {{ ref('dim_raw_material') }} rm
    ON rm.raw_material_id = r.raw_material_id
LEFT JOIN {{ ref('dim_flavour') }}  f
    ON f.flavour_id = r.flavour_id
LEFT JOIN {{ ref('dim_ingredient') }} i
    ON i.ingredient_id = r.ingredient_id
