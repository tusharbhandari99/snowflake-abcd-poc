{{ config(
    materialized='table',
    schema='ABCD_GOLD'
) }}

SELECT
    1 AS STATUS_ID,
    'ACTIVE' AS STATUS_NAME
UNION ALL
SELECT
    2 AS STATUS_ID,
    'INACTIVE' AS STATUS_NAME