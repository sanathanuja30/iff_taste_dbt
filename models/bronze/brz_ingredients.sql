-- bronze/brz_ingredients.sql
-- Raw ingestion of ingredients seed data.

SELECT
    ingredient_id::INTEGER                                  AS ingredient_id,
    TRIM(name)                                              AS ingredient_name,
    TRIM(chemical_formula)                                  AS chemical_formula,
    weight_in_grams::DECIMAL(10,4)                          AS weight_in_grams,
    cost_per_gram::DECIMAL(10,4)                            AS cost_per_gram,
    provider_id::INTEGER                                    AS provider_id,
    TRY_STRPTIME(generation_date, '%-d-%b-%y')::DATE        AS generation_date,
    batch_number::INTEGER                                   AS batch_number
FROM {{ ref('ingredients') }}
