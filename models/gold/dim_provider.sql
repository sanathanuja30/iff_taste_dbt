-- gold/dim_provider.sql
-- Provider dimension. Joins to dim_country for the country_key foreign key.

SELECT
    p.provider_id                                   AS provider_key,
    p.provider_id,
    p.provider_name,
    p.location_city,
    p.location_country,
    c.country_key
FROM {{ ref('slv_providers') }}     p
LEFT JOIN {{ ref('dim_country') }}  c
    ON c.country_name = p.location_country
