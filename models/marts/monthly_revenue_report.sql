{{ config(materialized='table') }}

with

orders as (

    select * from {{ ref('orders') }}

),

monthly_order_data as (

    select
        location_id,
        date_trunc('month', ordered_at) as month,
        sum(subtotal) as monthly_revenue,
        count(distinct order_id) as monthly_order_count

    from orders

    group by 1, 2

),

locations as (

    select * from {{ ref('locations') }}

),

with_location_name as (

    select
        monthly_order_data.location_id,
        locations.location_name,
        monthly_order_data.month,
        monthly_order_data.monthly_revenue,
        monthly_order_data.monthly_order_count

    from monthly_order_data

    left join locations on monthly_order_data.location_id = locations.location_id

),

with_window_calculations as (

    select
        location_id,
        location_name,
        month,
        monthly_revenue,
        monthly_order_count,

        -- calculate mom revenue growth percentage using lag window function
        case
            when lag(monthly_revenue) over (
                partition by location_id order by month
            ) is not null then
                (
                    (monthly_revenue - lag(monthly_revenue) over (partition by location_id order by month))
                    / lag(monthly_revenue) over (partition by location_id order by month)
                ) * 100
            else null
        end as mom_revenue_growth_pct,

        -- calculate cumulative revenue using sum window function
        sum(monthly_revenue) over (
            partition by location_id order by month rows unbounded preceding
        ) as cumulative_revenue

    from with_location_name

),

final as (

    select
        location_id,
        location_name,
        month,
        monthly_revenue,
        monthly_order_count,
        mom_revenue_growth_pct,
        cumulative_revenue,

        -- calculate revenue contribution percentage
        (monthly_revenue / cumulative_revenue) * 100 as revenue_contribution_pct

    from with_window_calculations

)

select * from final
