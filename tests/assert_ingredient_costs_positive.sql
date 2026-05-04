-- tests/assert_ingredient_costs_positive.sql
-- Data Quality Test 1: Ingredient cost and weight must be positive.
-- Failure means data entry errors or corrupt upstream data.
-- Action on failure: quarantine affected rows, alert data steward, do not promote to Gold.

SELECT ingredient_id, cost_per_gram, weight_in_grams
FROM {{ ref('slv_ingredients') }}
WHERE cost_per_gram <= 0
   OR weight_in_grams <= 0
   OR cost_per_gram IS NULL
   OR weight_in_grams IS NULL
