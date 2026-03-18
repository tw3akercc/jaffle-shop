{{ config(materialized='table') }}

with

orders as (

    select * from {{ ref('orders') }}

),

locations as (

    select * from {{ ref('locations') }}

),

-- extract year and month from ordered_at to create report_month
orders_with_month as (

    select
        order_id,
        location_id,
        subtotal,
        date_trunc('month', ordered_at) as report_month

    from orders

),

-- aggregate to location per month grain
monthly_aggregates as (

    select
        location_id,
        report_month,
        sum(subtotal) as monthly_revenue,
        count(distinct order_id) as monthly_order_count

    from orders_with_month

    group by
        location_id,
        report_month

),

-- calculate location total revenue for percentage calculation
location_totals as (

    select
        location_id,
        sum(monthly_revenue) as location_total_revenue

    from monthly_aggregates

    group by location_id

),

-- join locations for location_name and add window function calculations
with_calculations as (

    select
        monthly_aggregates.location_id,
        locations.location_name,
        monthly_aggregates.report_month,
        monthly_aggregates.monthly_revenue,
        monthly_aggregates.monthly_order_count,

        -- month over month growth percentage using LAG
        case
            when lag(monthly_aggregates.monthly_revenue) over (
                partition by monthly_aggregates.location_id
                order by monthly_aggregates.report_month
            ) is null then null
            else
                (
                    monthly_aggregates.monthly_revenue
                    - lag(monthly_aggregates.monthly_revenue) over (
                        partition by monthly_aggregates.location_id
                        order by monthly_aggregates.report_month
                    )
                )
                / lag(monthly_aggregates.monthly_revenue) over (
                    partition by monthly_aggregates.location_id
                    order by monthly_aggregates.report_month
                )
                * 100
        end as month_over_month_growth_pct,

        -- running cumulative revenue using SUM OVER
        sum(monthly_aggregates.monthly_revenue) over (
            partition by monthly_aggregates.location_id
            order by monthly_aggregates.report_month
            rows between unbounded preceding and current row
        ) as cumulative_revenue,

        -- percentage of location's total revenue
        monthly_aggregates.monthly_revenue
        / location_totals.location_total_revenue
        * 100 as monthly_revenue_pct_of_total

    from monthly_aggregates

    left join locations
        on monthly_aggregates.location_id = locations.location_id

    left join location_totals
        on monthly_aggregates.location_id = location_totals.location_id

)

select * from with_calculations
