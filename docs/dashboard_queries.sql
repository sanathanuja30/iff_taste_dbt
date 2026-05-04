-- =============================================================================
-- IFF Taste Analytics – Dashboard Sample Queries
-- These queries illustrate how the Gold layer dimensional model feeds each dashboard.
-- All queries target the main_gold schema.
-- =============================================================================


-- =============================================================================
-- DASHBOARD 1: Provider Inventory Analysis
-- Description: Ingredients held per provider, total stock value.
-- Filter: Provider country
-- =============================================================================

-- Q1a: Total stock value per provider, filterable by provider country
SELECT
    p.provider_name,
    p.location_city,
    p.location_country,
    COUNT(DISTINCT fi.ingredient_key)               AS num_ingredients,
    SUM(fi.stock_value_dollar)                      AS total_stock_value_usd
FROM main_gold.fact_provider_inventory fi
JOIN main_gold.dim_provider p ON p.provider_key = fi.provider_key
-- Optional filter by country:
-- WHERE p.location_country = 'Germany'
GROUP BY p.provider_name, p.location_city, p.location_country
ORDER BY total_stock_value_usd DESC;


-- Q1b: Ingredient-level detail for a single provider
-- (drill-down for the Provider Inventory Analysis dashboard)
SELECT
    fi.provider_name,
    fi.ingredient_name,
    fi.chemical_formula,
    fi.weight_in_grams,
    fi.cost_per_gram,
    fi.stock_value_dollar
FROM main_gold.fact_provider_inventory fi
WHERE fi.provider_country = 'Netherlands'   -- parameterise this
ORDER BY fi.stock_value_dollar DESC;


-- =============================================================================
-- DASHBOARD 2: Recipe Drill-down
-- Description: All constituents of a recipe; relative importance of each component.
-- Filters: Raw material, Flavour, Ingredient, Provider name, Provider country
-- =============================================================================

-- Q2a: All details for a specific recipe
SELECT
    fr.recipe_id,
    fr.raw_material_name,
    fr.raw_material_ratio,
    fr.flavour_name,
    fr.flavour_ratio,
    fr.ingredient_name,
    fr.ingredient_ratio,
    fr.provider_name,
    fr.provider_country,
    fr.heat_process,
    fr.has_heat_process,
    fr.yield_pct
FROM main_gold.fact_recipes fr
WHERE fr.recipe_id = 'PHMV';  -- parameterise this


-- Q2b: Relative importance – how many recipes use each raw material?
-- If we lose access to a raw material, how many recipes are affected?
SELECT
    rm.raw_material_name,
    COUNT(DISTINCT fr.recipe_id)                    AS recipes_affected,
    ROUND(
        COUNT(DISTINCT fr.recipe_id) * 100.0 /
        (SELECT COUNT(DISTINCT recipe_id) FROM main_gold.fact_recipes),
        2
    )                                               AS pct_of_all_recipes
FROM main_gold.fact_recipes fr
JOIN main_gold.dim_raw_material rm ON rm.raw_material_id = fr.raw_material_key
-- Optional filters:
-- WHERE fr.provider_country = 'Italy'
GROUP BY rm.raw_material_name
ORDER BY recipes_affected DESC;


-- Q2c: Relative importance – how many recipes use each flavour?
SELECT
    f.flavour_name,
    COUNT(DISTINCT fr.recipe_id)                    AS recipes_affected,
    ROUND(
        COUNT(DISTINCT fr.recipe_id) * 100.0 /
        (SELECT COUNT(DISTINCT recipe_id) FROM main_gold.fact_recipes),
        2
    )                                               AS pct_of_all_recipes
FROM main_gold.fact_recipes fr
JOIN main_gold.dim_flavour f ON f.flavour_id = fr.flavour_key
-- Optional filters:
-- WHERE fr.raw_material_name = 'Fatty Acid'
GROUP BY f.flavour_name
ORDER BY recipes_affected DESC;


-- Q2d: Relative importance – how many recipes use each ingredient, by provider?
SELECT
    i.ingredient_name,
    i.provider_name,
    i.provider_country,
    COUNT(DISTINCT fr.recipe_id)                    AS recipes_affected
FROM main_gold.fact_recipes fr
JOIN main_gold.dim_ingredient i ON i.ingredient_id = fr.ingredient_key
-- Optional filters:
-- WHERE i.provider_country = 'France'
GROUP BY i.ingredient_name, i.provider_name, i.provider_country
ORDER BY recipes_affected DESC;


-- =============================================================================
-- DASHBOARD 3: Sales Performance Analysis
-- Description: Most valuable customers; most valuable flavours.
-- Filters: Customer name, Customer country, Flavour name, Transaction country,
--          Transaction time period (years back, quarters)
-- =============================================================================

-- Q3a: Most valuable customers (total sales in USD)
SELECT
    cu.customer_name,
    cu.location_country                             AS customer_country,
    COUNT(DISTINCT fst.transaction_id)              AS num_transactions,
    SUM(fst.amount_dollar)                          AS total_sales_usd
FROM main_gold.fact_sales_transactions fst
JOIN main_gold.dim_customer cu ON cu.customer_id = fst.customer_key
-- Optional filters:
-- WHERE cu.location_country = 'Germany'
-- AND fst.transaction_country = 'France'
-- AND fst.transaction_date >= (CURRENT_DATE - INTERVAL '2 years')   -- last 2 years
-- AND d.year_quarter_label IN ('2024-Q1', '2024-Q2')                -- by quarter
GROUP BY cu.customer_name, cu.location_country
ORDER BY total_sales_usd DESC;


-- Q3b: Most valuable flavours (by USD sales and transaction count)
SELECT
    f.flavour_name,
    COUNT(DISTINCT fst.transaction_id)              AS num_transactions,
    SUM(fst.amount_dollar)                          AS total_sales_usd
FROM main_gold.fact_sales_transactions fst
JOIN main_gold.dim_flavour f ON f.flavour_id = fst.flavour_key
-- Optional filters:
-- WHERE fst.transaction_country = 'India'
-- AND fst.transaction_year >= YEAR(CURRENT_DATE) - 1       -- last N years
GROUP BY f.flavour_name
ORDER BY total_sales_usd DESC;


-- Q3c: Sales performance by year and quarter (time period filter)
SELECT
    d.year,
    d.quarter,
    d.year_quarter_label,
    COUNT(DISTINCT fst.transaction_id)              AS num_transactions,
    SUM(fst.amount_dollar)                          AS total_sales_usd,
    SUM(fst.quantity_liters)                        AS total_volume_liters
FROM main_gold.fact_sales_transactions fst
JOIN main_gold.dim_date d ON d.date_key = fst.date_key
WHERE fst.transaction_date >= (CURRENT_DATE - INTERVAL '3 years')   -- last 3 years
GROUP BY d.year, d.quarter, d.year_quarter_label
ORDER BY d.year, d.quarter;


-- =============================================================================
-- DASHBOARD 4: Flavour Description Tracker
-- Description: Historical changelog of flavour descriptions.
-- No filters specified; browse all versions.
-- =============================================================================

-- Q4a: All flavours that have had a description change
SELECT
    flavour_id,
    flavour_name,
    description                                     AS description_version,
    valid_from,
    valid_to,
    batch_number,
    is_current
FROM main_gold.dim_flavour_history
ORDER BY flavour_id, batch_number;


-- Q4b: Only flavours whose description changed between batches
SELECT
    h1.flavour_id,
    h1.flavour_name,
    h1.description                                  AS original_description,
    h2.description                                  AS updated_description,
    h2.valid_from                                   AS updated_on
FROM main_gold.dim_flavour_history h1
JOIN main_gold.dim_flavour_history h2
    ON h1.flavour_id = h2.flavour_id
    AND h1.batch_number = 1
    AND h2.batch_number = 2
    AND h1.description != h2.description
ORDER BY h1.flavour_id;


-- =============================================================================
-- BONUS: Country dimension – cross-source verification
-- =============================================================================

-- Q5: Countries that appear in all three sources (providers, customers, transactions)
SELECT
    country_name,
    appears_in_sources
FROM main_gold.dim_country
WHERE appears_in_sources LIKE '%customer%'
  AND appears_in_sources LIKE '%provider%'
  AND appears_in_sources LIKE '%transaction%'
ORDER BY country_name;
