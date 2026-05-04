-- gold/dim_flavour.sql
-- Flavour dimension – current snapshot only (latest description per flavour).
-- For historical description tracking, analysts should use dim_flavour_history.

SELECT
    flavour_id                                      AS flavour_key,
    flavour_id,
    flavour_name,
    description                                     AS current_description,
    valid_from                                      AS description_valid_from
FROM {{ ref('slv_flavours_current') }}
