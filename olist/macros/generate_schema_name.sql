{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set dev_prefix = env_var('DBT_SCHEMA_PREFIX', target.user | lower) -%}

    {%- if node.resource_type == 'seed' -%}
        {{ custom_schema_name | trim }}
    {%- elif target.name == 'prod' -%}
        {{ custom_schema_name | trim }}
    {%- else -%}
        {{ dev_prefix }}_{{ custom_schema_name | trim }}
    {%- endif -%}

{%- endmacro %}