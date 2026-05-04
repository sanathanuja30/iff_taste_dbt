-- bronze/brz_customers.sql
-- Raw ingestion of customers seed data.
-- Casts types; no business logic applied here.

SELECT
    customer_id::INTEGER                                    AS customer_id,
    name                                                    AS customer_name,
    TRIM(location_city)                                     AS location_city,
    TRIM(location_country)                                  AS location_country,
    STRPTIME(REPLACE(generation_date, '/', '/'), '%m/%d/%Y')::DATE AS generation_date,
    batch_number::INTEGER                                   AS batch_number
FROM {{ ref('customers') }}
