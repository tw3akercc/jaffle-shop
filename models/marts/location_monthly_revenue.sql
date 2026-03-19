{{ config(materialized='table') }}

with

orders as (

    select * from {{ ref('orders') }}

),

locations as (

    select * from {{ ref('locations') }}

),

time_spine as (

    select * from {{ ref('metricflow_time_spine') }}

),

-- derive min/max month bounds from orders
order_date_bounds as (

    select
        {{ dbt.date_trunc('month', 'min(ordered_at)') }} as min_month,
        {{ dbt.date_trunc('month', 'max(ordered_at)') }} as max_month

    from orders

),

-- build month spine from time_spine, truncated to month and filtered to order date range
month_spine as (

    select distinct
        {{ dbt.date_trunc('month', 'date_day') }} as month_start

    from time_spine

    cross join order_date_bounds

    where {{ dbt.date_trunc('month', 'date_day') }} between order_date_bounds.min_month and order_date_bounds.max_month

),

-- cross join all locations × all months to ensure zero-fill for inactive locations
location_months as (

    select
        locations.location_id,
        locations.location_name,
        month_spine.month_start

    from locations

    cross join month_spine

),

-- aggregate monthly order data from orders
monthly_orders as (

    select
        location_id,
        {{ dbt.date_trunc('month', 'ordered_at') }} as month_start,
        sum(order_total) as monthly_revenue,
        count(order_id) as monthly_order_count

    from orders

    group by 1, 2

),

-- left join aggregated orders onto the cross join result
joined as (

    select
        location_months.location_id,
        location_months.location_name,
        location_months.month_start,
        coalesce(monthly_orders.monthly_revenue, 0) as monthly_revenue,
        coalesce(monthly_orders.monthly_order_count, 0) as monthly_order_count

    from location_months

    left join monthly_orders
        on location_months.location_id = monthly_orders.location_id
        and location_months.month_start = monthly_orders.month_start

),

-- compute window functions for trend metrics
with_windows as (

    select
        joined.*,

        -- month-over-month revenue growth percentage
        (
            joined.monthly_revenue
            - lag(joined.monthly_revenue) over (
                partition by joined.location_id
                order by joined.month_start
            )
        )
        / nullif(
            lag(joined.monthly_revenue) over (
                partition by joined.location_id
                order by joined.month_start
            ),
            0
        )
        * 100 as mom_revenue_growth_pct,

        -- cumulative revenue per location
        sum(joined.monthly_revenue) over (
            partition by joined.location_id
            order by joined.month_start
            rows between unbounded preceding and current row
        ) as cumulative_revenue,

        -- location's all-time total revenue for percentage calculation
        sum(joined.monthly_revenue) over (
            partition by joined.location_id
        ) as location_total_revenue

    from joined

),

-- compute percentage of all-time location revenue and add formatted month label
final as (

    select
        location_id,
        location_name,
        month_start,
        strftime('%B %Y', month_start) as month,
        monthly_revenue,
        monthly_order_count,
        mom_revenue_growth_pct,
        cumulative_revenue,
        coalesce(
            (
                monthly_revenue
                / nullif(location_total_revenue, 0)
                * 100
            ),
            0
        ) as pct_of_total_revenue

    from with_windows

)

select * from final
