-- silver/slv_sales_transactions.sql
-- Cleaned sales transactions.
-- transaction_country_raw arrives in ALL CAPS; normalised to Title Case here.

WITH normalised AS (
    SELECT
        transaction_id,
        customer_id,
        flavour_id,
        quantity_liters,
        {{ title_case('transaction_country_raw') }} AS transaction_country,
        transaction_town,
        postal_code,
        amount_dollar,
        batch_number
    FROM {{ ref('brz_sales_transactions') }}
),
ranked AS (
    SELECT
        n.transaction_id,
        n.customer_id,
        n.flavour_id,
        n.quantity_liters,
        n.transaction_country,
        n.transaction_town,
        n.postal_code,
        n.amount_dollar,
        n.batch_number,
        b.transaction_date,
        b.generation_date,
        ROW_NUMBER() OVER (PARTITION BY n.transaction_id ORDER BY n.batch_number DESC) AS rn
    FROM normalised n
    JOIN {{ ref('brz_sales_transactions') }} b
        ON b.transaction_id = n.transaction_id AND b.batch_number = n.batch_number
)
SELECT
    transaction_id,
    customer_id,
    flavour_id,
    quantity_liters,
    transaction_date,
    transaction_country,
    transaction_town,
    postal_code,
    amount_dollar,
    YEAR(transaction_date)                          AS transaction_year,
    QUARTER(transaction_date)                       AS transaction_quarter,
    generation_date,
    batch_number
FROM ranked
WHERE rn = 1
