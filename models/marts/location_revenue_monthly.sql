{{ config(materialized='table') }}

with

orders as (

    select * from {{ ref('orders') }}

),

locations as (

    select * from {{ ref('locations') }}

),

-- monthly aggregation by location
monthly_agg as (

    select
        location_id,
        {{ dbt.date_trunc('month', 'ordered_at') }} as revenue_month,
        sum(order_total) as monthly_revenue,
        count(order_id) as monthly_order_count

    from orders

    group by 1, 2

),

-- join location name before window functions
with_location_name as (

    select
        monthly_agg.location_id,
        locations.location_name,
        monthly_agg.revenue_month,
        monthly_agg.monthly_revenue,
        monthly_agg.monthly_order_count

    from monthly_agg

    left join
        locations
        on monthly_agg.location_id = locations.location_id

),

-- window functions: mom growth, cumulative revenue, pct of total
with_windows as (

    select
        location_id,
        location_name,
        revenue_month,
        monthly_revenue,
        monthly_order_count,
        lag(monthly_revenue) over (
            partition by location_id
            order by revenue_month
        ) as prev_monthly_revenue,
        sum(monthly_revenue) over (
            partition by location_id
            order by revenue_month
            rows between unbounded preceding and current row
        ) as cumulative_revenue,
        sum(monthly_revenue) over (
            partition by location_id
        ) as location_total_revenue

    from with_location_name

),

final as (

    select
        location_id,
        location_name,
        revenue_month,
        monthly_revenue,
        monthly_order_count,
        round(
            (monthly_revenue - prev_monthly_revenue)
            / prev_monthly_revenue * 100,
            2
        ) as mom_revenue_growth_pct,
        cumulative_revenue,
        round(
            monthly_revenue / location_total_revenue * 100,
            2
        ) as pct_of_location_total_revenue

    from with_windows

)

select * from final
