-- gold/fact_sales_transactions.sql
-- Sales transaction fact table.
-- Grain: one row per transaction.
-- Foreign keys to dim_customer, dim_flavour, dim_date, and dim_country (transaction country).

SELECT
    st.transaction_id,
    st.customer_id                                  AS customer_key,
    cu.customer_name,
    cu.location_country                             AS customer_country,
    st.flavour_id                                   AS flavour_key,
    f.flavour_name,
    st.transaction_date                             AS date_key,
    d.year                                          AS transaction_year,
    d.quarter                                       AS transaction_quarter,
    d.year_quarter_label,
    st.transaction_country,
    tc.country_key                                  AS transaction_country_key,
    st.transaction_town,
    st.postal_code,
    -- Measures
    st.quantity_liters,
    st.amount_dollar
FROM {{ ref('slv_sales_transactions') }} st
LEFT JOIN {{ ref('dim_customer') }}      cu
    ON cu.customer_id = st.customer_id
LEFT JOIN {{ ref('dim_flavour') }}       f
    ON f.flavour_id = st.flavour_id
LEFT JOIN {{ ref('dim_date') }}          d
    ON d.date_key = st.transaction_date
LEFT JOIN {{ ref('dim_country') }}       tc
    ON tc.country_name = st.transaction_country
