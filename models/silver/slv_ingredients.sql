-- silver/slv_ingredients.sql
-- Cleaned ingredients. Deduplication: highest batch_number wins.

WITH ranked AS (
    SELECT
        ingredient_id,
        ingredient_name,
        chemical_formula,
        weight_in_grams,
        cost_per_gram,
        provider_id,
        generation_date,
        batch_number,
        ROW_NUMBER() OVER (PARTITION BY ingredient_id ORDER BY batch_number DESC) AS rn
    FROM {{ ref('brz_ingredients') }}
)
SELECT
    ingredient_id,
    ingredient_name,
    chemical_formula,
    weight_in_grams,
    cost_per_gram,
    provider_id,
    generation_date,
    batch_number
FROM ranked
WHERE rn = 1
