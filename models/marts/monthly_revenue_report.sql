{{ config(materialized='table') }}

with

orders as (

    select * from {{ ref('orders') }}

),

locations as (

    select * from {{ ref('locations') }}

),

-- aggregate orders by location and month
monthly_orders as (

    select
        location_id,
        -- extract first day of month (YYYY-MM-01 format)
        date_trunc('month', ordered_at) as month,
        sum(subtotal) as monthly_revenue,
        count(distinct order_id) as monthly_order_count

    from orders

    group by 1, 2

),

-- join with locations to get location_name
monthly_with_location as (

    select
        monthly_orders.location_id,
        locations.location_name,
        monthly_orders.month,
        monthly_orders.monthly_revenue,
        monthly_orders.monthly_order_count

    from monthly_orders

    left join locations
        on monthly_orders.location_id = locations.location_id

),

-- calculate window functions for growth, cumulative, and contribution metrics
final as (

    select
        location_id,
        location_name,
        month,
        monthly_revenue,
        monthly_order_count,

        -- month-over-month revenue growth percentage
        -- first month for each location will be null
        (
            (monthly_revenue - lag(monthly_revenue) over (
                partition by location_id
                order by month
            ))
            / nullif(lag(monthly_revenue) over (
                partition by location_id
                order by month
            ), 0)
        ) * 100 as mom_revenue_growth_pct,

        -- running sum of revenue per location
        sum(monthly_revenue) over (
            partition by location_id
            order by month
            rows between unbounded preceding and current row
        ) as cumulative_revenue,

        -- total revenue for all time per location
        sum(monthly_revenue) over (
            partition by location_id
        ) as location_total_revenue

    from monthly_with_location

),

-- calculate revenue contribution percentage
with_contribution as (

    select
        location_id,
        location_name,
        month,
        monthly_revenue,
        monthly_order_count,
        mom_revenue_growth_pct,
        cumulative_revenue,
        location_total_revenue,

        -- percentage of this month's revenue relative to total location revenue
        (monthly_revenue / nullif(location_total_revenue, 0)) * 100 as revenue_contribution_pct

    from final

)

select * from with_contribution
