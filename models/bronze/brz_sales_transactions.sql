-- bronze/brz_sales_transactions.sql
-- Raw ingestion of sales_transactions seed data.
-- transaction_country arrives in UPPER CASE; normalised in Silver.

SELECT
    transaction_id::INTEGER                                         AS transaction_id,
    customer_id::INTEGER                                            AS customer_id,
    flavour_id::INTEGER                                             AS flavour_id,
    quantity_liters::DECIMAL(14,4)                                  AS quantity_liters,
    TRY_STRPTIME(transaction_date, '%m/%d/%y')::DATE                AS transaction_date,
    TRIM(transaction_country)                                       AS transaction_country_raw,
    TRIM(transaction_town)                                          AS transaction_town,
    TRIM(postal_code)                                               AS postal_code,
    amount_dollar::DECIMAL(18,2)                                    AS amount_dollar,
    TRY_STRPTIME(generation_date, '%m/%d/%y')::DATE                 AS generation_date,
    batch_number::INTEGER                                           AS batch_number
FROM {{ ref('sales_transactions') }}
