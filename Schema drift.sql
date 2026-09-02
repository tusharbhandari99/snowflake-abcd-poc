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



  CREATE OR REPLACE PROCEDURE ABCD_POC_DB.ABCD_SILVER.CHECK_AND_NOTIFY_SCHEMA_DRIFT(
    TARGET_DB STRING,
    TARGET_SCHEMA STRING,
    TARGET_TABLE STRING
)
RETURNS STRING
LANGUAGE SQL
EXECUTE AS CALLER
AS
DECLARE
    drift_count INTEGER DEFAULT 0;
    drift_summary STRING DEFAULT '';
    email_body STRING DEFAULT '';
    alert_query STRING;
    c1 CURSOR FOR 
        WITH current_cols AS (
            SELECT 
                UPPER(COLUMN_NAME) AS COLUMN_NAME, 
                UPPER(DATA_TYPE) AS DATA_TYPE, 
                IS_NULLABLE
            FROM IDENTIFIER(:TARGET_DB || '.INFORMATION_SCHEMA.COLUMNS')
            WHERE TABLE_SCHEMA = UPPER(:TARGET_SCHEMA)
              AND TABLE_NAME = UPPER(:TARGET_TABLE)
        ),
        baseline_cols AS (
            SELECT 
                UPPER(COLUMN_NAME) AS COLUMN_NAME, 
                UPPER(DATA_TYPE) AS DATA_TYPE, 
                IS_NULLABLE
            FROM ABCD_POC_DB.ABCD_SILVER.SCHEMA_BASELINE_CATALOG
            WHERE TABLE_SCHEMA = UPPER(:TARGET_SCHEMA)
              AND TABLE_NAME = UPPER(:TARGET_TABLE)
        )
        -- 1. Detect Removed Columns
        SELECT 
            'REMOVED_COLUMN' AS DRIFT_TYPE, 
            b.COLUMN_NAME, 
            b.DATA_TYPE AS BASELINE_VAL, 
            'MISSING' AS CURRENT_VAL
        FROM baseline_cols b
        LEFT JOIN current_cols c ON b.COLUMN_NAME = c.COLUMN_NAME
        WHERE c.COLUMN_NAME IS NULL
        
        UNION ALL
        
        -- 2. Detect Added Columns
        SELECT 
            'ADDED_COLUMN' AS DRIFT_TYPE, 
            c.COLUMN_NAME, 
            'NONE' AS BASELINE_VAL, 
            c.DATA_TYPE AS CURRENT_VAL
        FROM current_cols c
        LEFT JOIN baseline_cols b ON c.COLUMN_NAME = b.COLUMN_NAME
        WHERE b.COLUMN_NAME IS NULL
        
        UNION ALL
        
        -- 3. Detect Modified Data Types
        SELECT 
            'MODIFIED_DATA_TYPE' AS DRIFT_TYPE, 
            c.COLUMN_NAME, 
            b.DATA_TYPE AS BASELINE_VAL, 
            c.DATA_TYPE AS CURRENT_VAL
        FROM current_cols c
        JOIN baseline_cols b ON c.COLUMN_NAME = b.COLUMN_NAME
        WHERE c.DATA_TYPE <> b.DATA_TYPE;
BEGIN
    -- Iterate through drift findings
    FOR record IN c1 DO
        drift_count := drift_count + 1;
        drift_summary := drift_summary || '\n - [' || record.DRIFT_TYPE || '] Column: ' || record.COLUMN_NAME 
                         || ' | Expected: ' || record.BASELINE_VAL 
                         || ' | Current: ' || record.CURRENT_VAL;
    END FOR;

    -- If drift exists, send the notification email
    IF (drift_count > 0) THEN
        email_body := 'WARNING: Schema drift detected on table: ' 
                      || UPPER(:TARGET_DB) || '.' || UPPER(:TARGET_SCHEMA) || '.' || UPPER(:TARGET_TABLE) 
                      || '\n\nDiscrepancies identified (' || drift_count || '):' 
                      || drift_summary;

        -- Send email alert using SYSTEM$SEND_EMAIL
        CALL SYSTEM$SEND_EMAIL(
            'schema_drift_email_int',
            'tushar@yourcompany.com',
            'ALERT: Schema Drift Detected in ' || UPPER(:TARGET_TABLE),
            :email_body
        );

        RETURN 'DRIFT DETECTED: ' || drift_count || ' issue(s) found. Notification dispatched.';
    END IF;

    RETURN 'PASS: Schema matches baseline. No drift detected.';
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