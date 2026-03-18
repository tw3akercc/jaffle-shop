-- Custom test to verify cumulative_revenue is non-decreasing over time for each location
{% test cumulative_revenue_non_decreasing(model, column_name, partition_by) %}

with

lag_calc as (

    select
        {{ partition_by }},
        {{ column_name }},
        lag({{ column_name }}) over (
            partition by {{ partition_by }}
            order by report_month
        ) as prev_cumulative_revenue

    from {{ model }}

),

violations as (

    select *
    from lag_calc
    where prev_cumulative_revenue is not null
      and {{ column_name }} < prev_cumulative_revenue

)

select * from violations

{% endtest %}
