{{ config(materialized='table') }}

with

orders as (

    select
        order_id,
        location_id,
        subtotal,
        ordered_at
    from {{ ref('orders') }}

),

locations as (

    select
        location_id,
        location_name
    from {{ ref('locations') }}

),

monthly_orders as (

    select
        location_id,
        {{ dbt.date_trunc('month', 'ordered_at') }} as revenue_month,
        sum(subtotal) as monthly_revenue,
        count(order_id) as monthly_order_count

    from orders

    group by 1, 2

),

window_calcs as (

    select
        location_id,
        revenue_month,
        monthly_revenue,
        monthly_order_count,
        lag(monthly_revenue, 1) over (
            partition by location_id
            order by revenue_month
        ) as prior_month_revenue,
        sum(monthly_revenue) over (
            partition by location_id
            order by revenue_month
        ) as cumulative_revenue,
        monthly_revenue / sum(monthly_revenue) over (
            partition by location_id
        ) as pct_of_location_revenue

    from monthly_orders

),

final as (

    select
        window_calcs.location_id,
        locations.location_name,
        window_calcs.revenue_month,
        window_calcs.monthly_revenue,
        window_calcs.monthly_order_count,
        -- NULL for first month per location (natural lag() behavior)
        (window_calcs.monthly_revenue - window_calcs.prior_month_revenue)
            / window_calcs.prior_month_revenue as revenue_mom_growth_pct,
        window_calcs.cumulative_revenue,
        window_calcs.pct_of_location_revenue

    from window_calcs

    left join locations
        on window_calcs.location_id = locations.location_id

)

select * from final
