-- gold/dim_customer.sql
-- Customer dimension. Joins to dim_country for the country_key foreign key.

SELECT
    cu.customer_id                                  AS customer_key,
    cu.customer_id,
    cu.customer_name,
    cu.location_city,
    cu.location_country,
    c.country_key
FROM {{ ref('slv_customers') }}     cu
LEFT JOIN {{ ref('dim_country') }}  c
    ON c.country_name = cu.location_country
