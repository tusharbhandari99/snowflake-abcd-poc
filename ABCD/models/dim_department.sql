{{ config(
    materialized='table',
    schema='ABCD_GOLD'
) }}

WITH source_data AS (
    SELECT 1 AS dept_id, 'Cardiology' AS dept_name, 'Building A' AS locations
    UNION ALL
    SELECT 2 AS dept_id, 'Neurology' AS dept_name, 'Building B' AS locations
    UNION ALL
    SELECT 3 AS dept_id, 'Oncology' AS dept_name, 'Building C' AS locations
)

SELECT 
    dept_id,
    dept_name,
    location,
    CURRENT_TIMESTAMP() AS created_at
FROM source_data