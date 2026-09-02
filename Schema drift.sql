USE ROLE ACCOUNTADMIN;

-- 1. Create email notification integration
CREATE OR REPLACE NOTIFICATION INTEGRATION schema_drift_email_int
    TYPE = EMAIL
    ENABLED = TRUE
    ALLOWED_RECIPIENTS = ('tushar.bhandari@infojiniconsulting.com');

USE DATABASE ABCD_POC_DB;
USE SCHEMA ABCD_SILVER;

CREATE OR REPLACE TABLE SCHEMA_BASELINE_CATALOG (
    TABLE_DATABASE VARCHAR,
    TABLE_SCHEMA   VARCHAR,
    TABLE_NAME     VARCHAR,
    COLUMN_NAME    VARCHAR,
    DATA_TYPE      VARCHAR,
    IS_NULLABLE    VARCHAR,
    LAST_CERTIFIED TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Seed the baseline with current source/bronze tables
INSERT INTO ABCD_POC_DB.ABCD_SILVER.SCHEMA_BASELINE_CATALOG (
    TABLE_DATABASE,
    TABLE_SCHEMA,
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
)
SELECT 
    TABLE_CATALOG,
    TABLE_SCHEMA,
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM ABCD_POC_DB.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_CATALOG = 'ABCD_POC_DB'
  AND TABLE_SCHEMA = 'ABCD_BRONZE' 
  AND TABLE_NAME = 'RAW_SAMPLE_INGEST';



USE ROLE ACCOUNTADMIN;

-- 1. Create the email notification integration
CREATE OR REPLACE NOTIFICATION INTEGRATION email_alert_integration
    TYPE = EMAIL
    ENABLED = TRUE
    ALLOWED_RECIPIENTS = ('your-email@example.com'); -- Must be a verified user email in Snowflake

-- 2. Grant usage to the role running CI/CD
GRANT USAGE ON INTEGRATION schema_drift_email_int TO ROLE dbt_cicd_prod_role;

USE DATABASE ABCD_POC_DB;
USE SCHEMA ABCD_SILVER;

CREATE OR REPLACE PROCEDURE SEND_PIPELINE_EMAIL(
    SUBJECT_TEXT STRING,
    BODY_TEXT STRING
)
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
BEGIN
    CALL SYSTEM$SEND_EMAIL(
        'schema_drift_email_int',
        'tushar.bhandari@infojiniconsulting.com',
        :SUBJECT_TEXT,
        :BODY_TEXT
    );
    RETURN 'Email successfully sent via Snowflake.';
END;





select * from ABCD_POC_DB.ABCD_BRONZE.RAW_SAMPLE_INGEST;
PAYLOAD	_INGESTED_AT
{
  "accessioned_at": "2026-08-20 10:45:00",
  "collected_at": "2026-08-20 08:30:00",
  "event_id": "EVT-1001",
  "patient_mrn": "MRN-12345",
  "patient_zip": "94107",
  "provider_name": "Dr. Sarah Jenkins",
  "provider_npi": "1982736450",
  "qc_status": "PASS",
  "sample_id": "SMP-9001"
}	2026-08-26 06:08:41.751
{
  "accessioned_at": "2026-08-20 12:15:00",
  "collected_at": "2026-08-20 09:00:00",
  "event_id": "EVT-1002",
  "patient_mrn": "MRN-67890",
  "patient_zip": "02138",
  "provider_name": "Dr. Mark Vance",
  "provider_npi": "1457892310",
  "qc_status": "FLAGGED",
  "sample_id": "SMP-9002"
}	2026-08-26 06:08:59.992