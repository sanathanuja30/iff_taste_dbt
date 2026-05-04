-- tests/assert_recipe_ratios_sum_valid.sql
-- Data Quality Test 2: Ratios in a recipe (raw_material + flavour + ingredient)
-- should sum to approximately 1.0 (within a 1% tolerance).
-- A sum far from 1 indicates a data entry error or missing/duplicate components.
-- Action on failure: log to a data quality monitoring table, alert operations team.

SELECT
    recipe_id,
    raw_material_ratio + flavour_ratio + ingredient_ratio AS ratio_sum
FROM {{ ref('slv_recipes') }}
WHERE ABS((raw_material_ratio + flavour_ratio + ingredient_ratio) - 1.0) > 0.01
