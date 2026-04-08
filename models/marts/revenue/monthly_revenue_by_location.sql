{{ config(materialized='table') }}

with

orders as (

    select * from {{ ref('stg_orders') }}

),

locations as (

    select * from {{ ref('stg_locations') }}

),

monthly_aggregated as (

    select
        orders.location_id,
        {{ dbt.date_trunc('month', 'orders.ordered_at') }} as report_month,
        sum(orders.order_total) as monthly_revenue,
        count(orders.order_id) as monthly_order_count

    from orders

    group by
        orders.location_id,
        {{ dbt.date_trunc('month', 'orders.ordered_at') }}

    having count(orders.order_id) >= 1

),

with_locations as (

    select
        monthly_aggregated.*,
        locations.location_name

    from monthly_aggregated

    left join
        locations
        on monthly_aggregated.location_id = locations.location_id

),

with_mom_growth as (

    select
        *,
        (monthly_revenue - lag(monthly_revenue) over (
            partition by location_id
            order by report_month
        )) / lag(monthly_revenue) over (
            partition by location_id
            order by report_month
        ) * 100 as revenue_growth_mom_pct

    from with_locations

),

with_cumulative as (

    select
        *,
        sum(monthly_revenue) over (
            partition by location_id
            order by report_month
            rows between unbounded preceding and current row
        ) as cumulative_revenue

    from with_mom_growth

),

with_contribution as (

    select
        *,
        monthly_revenue / sum(monthly_revenue) over (
            partition by location_id
        ) * 100 as revenue_contribution_pct

    from with_cumulative

)

select
    location_id,
    location_name,
    report_month,
    monthly_revenue,
    monthly_order_count,
    revenue_growth_mom_pct,
    cumulative_revenue,
    revenue_contribution_pct

from with_contribution

order by
    location_id,
    report_month
