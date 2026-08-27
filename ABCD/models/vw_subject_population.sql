{{ config(schema='ABCD_DEID', materialized='view') }}

SELECT
    event_id,
    sample_id,
    SHA2(CONCAT('ABCD_SALT_2026_', patient_mrn), 256) AS deid_patient_id,
    SUBSTRING(patient_zip, 1, 3) || 'XX'             AS generalized_zip,
    provider_npi,
    qc_status,
    turnaround_time_minutes
FROM {{ ref('fct_sample_event') }}