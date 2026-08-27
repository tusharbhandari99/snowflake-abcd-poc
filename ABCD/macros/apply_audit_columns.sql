{% macro apply_audit_columns(source_system_name='S3_HEALTHOMICS') %}
    , CURRENT_TIMESTAMP()               AS _loaded_at
    , CURRENT_TIMESTAMP()               AS _source_updated_at
    , '{{ source_system_name }}'        AS _source_system
    , SHA2(CONCAT_WS('|', *), 256)      AS _record_hash
{% endmacro %}