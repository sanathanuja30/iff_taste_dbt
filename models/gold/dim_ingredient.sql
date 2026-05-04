-- gold/dim_ingredient.sql
-- Ingredient dimension. Links to dim_provider via provider_key.

SELECT
    i.ingredient_id                                 AS ingredient_key,
    i.ingredient_id,
    i.ingredient_name,
    i.chemical_formula,
    i.weight_in_grams,
    i.cost_per_gram,
    i.provider_id,
    p.provider_name,
    p.location_country                              AS provider_country
FROM {{ ref('slv_ingredients') }}   i
LEFT JOIN {{ ref('slv_providers') }} p
    ON p.provider_id = i.provider_id
