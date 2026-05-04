-- tests/assert_recipe_yield_valid.sql
-- Data Quality Test 3: Yield percentage must be > 0 and <= 100.
-- A yield of 0 is physically impossible; > 100 violates conservation of mass.
-- Action on failure: reject and quarantine affected recipes, alert data steward.

SELECT recipe_id, yield_pct
FROM {{ ref('slv_recipes') }}
WHERE yield_pct <= 0
   OR yield_pct > 100
   OR yield_pct IS NULL
