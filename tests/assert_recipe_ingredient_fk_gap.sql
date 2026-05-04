-- tests/assert_recipe_ingredient_fk_gap.sql
-- Data Quality Issue: 55,841 recipe rows reference ingredient_ids 1-100
-- that do not exist in the ingredients master table (which starts at id 101).
-- This indicates a data completeness gap in the ingredients seed file.
-- 
-- Impact: fact_recipes rows with these ingredients will have NULL provider/cost info.
-- Action: request the missing ingredients data (IDs 1-100) from the upstream system;
-- do not use these recipes in cost calculations until resolved.

SELECT DISTINCT recipe_id, ingredient_id
FROM {{ ref('slv_recipes') }}
WHERE ingredient_id NOT IN (SELECT ingredient_id FROM {{ ref('dim_ingredient') }})
LIMIT 100
