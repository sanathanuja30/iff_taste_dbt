-- bronze/brz_providers.sql
-- Raw ingestion of providers seed data.
-- Casts types; trims whitespace; no business logic.

SELECT
    provider_id::INTEGER                                    AS provider_id,
    TRIM(name)                                              AS provider_name,
    TRIM(location_city)                                     AS location_city,
    TRIM(location_country)                                  AS location_country,
    TRY_STRPTIME(generation_date, '%m/%d/%y')::DATE         AS generation_date,
    batch_number::INTEGER                                   AS batch_number
FROM {{ ref('providers') }}
