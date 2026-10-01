{{ config(materialized='table') }}

SELECT
    payload:event_id::STRING AS event_id,
    payload:sample_id::STRING AS sample_id,
    payload:patient_mrn::STRING AS patient_mrn,
    payload:patient_zip::STRING AS patient_zip,
    payload:provider_npi::STRING AS provider_npi,
    payload:provider_name::STRING AS provider_name,
    payload:qc_status::STRING AS qc_status,
    payload:collected_at::TIMESTAMP_NTZ AS collected_at,
    payload:accessioned_at::TIMESTAMP_NTZ AS accessioned_at
    {{ apply_audit_columns('S3_HEALTHOMICS') }}
FROM {{ source('bronze', 'RAW_SAMPLE_INGEST') }}