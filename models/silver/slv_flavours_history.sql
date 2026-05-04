-- silver/slv_flavours_history.sql
-- Flavour description history (SCD Type 2).
--
-- Business rule: flavours arrived in 2 batches; batch 2 may have updated descriptions.
-- We preserve ALL versions to support the "Flavour Description Tracker" dashboard.
-- Each row represents one version of a flavour's description.
-- is_current = TRUE marks the most recent version.

WITH all_versions AS (
    SELECT
        flavour_id,
        flavour_name,
        description,
        generation_date,
        batch_number,
        LEAD(generation_date) OVER (
            PARTITION BY flavour_id ORDER BY batch_number
        )                                           AS valid_to,
        LAG(description) OVER (
            PARTITION BY flavour_id ORDER BY batch_number
        )                                           AS prev_description
    FROM {{ ref('brz_flavours') }}
),
versioned AS (
    SELECT
        flavour_id,
        flavour_name,
        description,
        generation_date                             AS valid_from,
        COALESCE(valid_to, '9999-12-31'::DATE)      AS valid_to,
        batch_number,
        (prev_description IS NULL OR description != prev_description)
                                                    AS is_new_version
    FROM all_versions
    WHERE prev_description IS NULL OR description != prev_description
)
SELECT
    MD5(CAST(flavour_id AS VARCHAR) || '_' || CAST(batch_number AS VARCHAR))
                                                    AS flavour_version_key,
    flavour_id,
    flavour_name,
    description,
    valid_from,
    valid_to,
    batch_number,
    valid_to = '9999-12-31'::DATE                   AS is_current
FROM versioned
