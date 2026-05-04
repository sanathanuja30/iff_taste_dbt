-- gold/dim_flavour_history.sql
-- Flavour description history dimension (SCD Type 2).
-- Powers the "Flavour Description Tracker" dashboard.
-- Each row is a unique version of a flavour's description.

SELECT
    flavour_version_key,
    flavour_id,
    flavour_name,
    description,
    valid_from,
    valid_to,
    batch_number,
    is_current
FROM {{ ref('slv_flavours_history') }}
