{{ config(schema='ABCD_GOLD', materialized='table') }}

SELECT
    event_id,
    sample_id,
    patient_mrn,
    patient_zip,
    provider_npi,
    qc_status,
    collected_at,
    accessioned_at,
    DATEDIFF('minute', collected_at, accessioned_at) AS turnaround_time_minutes
    {{ apply_audit_columns('S3_HEALTHOMICS') }}
FROM {{ ref('stg_samples') }}