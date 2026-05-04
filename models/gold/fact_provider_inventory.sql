-- gold/fact_provider_inventory.sql
-- Provider inventory fact table.
-- Grain: one row per ingredient per provider.
-- Each ingredient is supplied by exactly one provider; this fact aggregates
-- the stock value (weight * cost_per_gram) to support the Provider Inventory
-- Analysis dashboard.

SELECT
    i.ingredient_id                                 AS ingredient_key,
    i.ingredient_name,
    i.chemical_formula,
    i.provider_id                                   AS provider_key,
    p.provider_name,
    p.location_city                                 AS provider_city,
    p.location_country                              AS provider_country,
    p.country_key,
    -- Measures
    i.weight_in_grams,
    i.cost_per_gram,
    -- Total monetary value of this ingredient's stock at the provider
    ROUND(i.weight_in_grams * i.cost_per_gram, 2)  AS stock_value_dollar
FROM {{ ref('dim_ingredient') }}     i
LEFT JOIN {{ ref('dim_provider') }}  p
    ON p.provider_id = i.provider_id
