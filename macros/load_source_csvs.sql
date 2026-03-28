{% macro load_source_csvs() %}
    {% if var('load_source_data', false) and execute %}

        {% set seed_dir = env_var('DBT_SEED_DIR', '') %}
        {% if seed_dir == '' %}
            {# Fall back to locating seeds relative to the dbt.duckdb file #}
            {% set seed_dir = '/workspace/cmn9kpu7y0001s701r372rwwp/seeds/jaffle-data' %}
        {% endif %}

        {% set tables = [
            'raw_customers',
            'raw_items',
            'raw_orders',
            'raw_products',
            'raw_stores',
            'raw_supplies'
        ] %}

        create schema if not exists raw;

        {% for table in tables %}
            create or replace table raw.{{ table }} as
                select * from read_csv_auto('{{ seed_dir }}/{{ table }}.csv');
        {% endfor %}

    {% endif %}
{% endmacro %}
