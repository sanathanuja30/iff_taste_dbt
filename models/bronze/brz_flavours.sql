-- bronze/brz_flavours.sql
-- Raw ingestion of flavours seed data.
-- Both batches are preserved here; deduplication happens in Silver.

SELECT
    flavour_id::INTEGER                                     AS flavour_id,
    TRIM(name)                                              AS flavour_name,
    TRIM(description)                                       AS description,
    TRY_STRPTIME(generation_date, '%m/%d/%y')::DATE         AS generation_date,
    batch_number::INTEGER                                   AS batch_number
FROM {{ ref('flavours') }}
