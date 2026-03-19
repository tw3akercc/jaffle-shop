{{ config(materialized='table') }}

with

locations as (

    select
        location_id,
        location_name,
        opened_date
    from {{ ref('stg_locations') }}

),

monthly_date_spine as (

    -- Generate distinct months from the time spine
    select distinct
        {{ dbt.date_trunc('month', 'date_day') }} as month
    from {{ ref('metricflow_time_spine') }}

),

location_month_grid as (

    -- Cross join locations with months, filtered to active months per location
    select
        locations.location_id,
        locations.location_name,
        monthly_date_spine.month
    from locations
    cross join monthly_date_spine
    where
        monthly_date_spine.month
        >= {{ dbt.date_trunc('month', 'locations.opened_date') }}
        and monthly_date_spine.month
        <= {{ dbt.date_trunc('month', 'current_date') }}

),

order_revenue as (

    -- Aggregate order revenue by location and month
    select
        location_id,
        {{ dbt.date_trunc('month', 'ordered_at') }} as month,
        sum(subtotal) as monthly_revenue,
        count(order_id) as monthly_order_count
    from {{ ref('stg_orders') }}
    group by 1, 2

),

joined_revenue as (

    -- Left join revenue onto the location-month grid
    select
        location_month_grid.location_id,
        location_month_grid.location_name,
        location_month_grid.month,
        coalesce(order_revenue.monthly_revenue, 0) as monthly_revenue,
        coalesce(order_revenue.monthly_order_count, 0) as monthly_order_count
    from location_month_grid
    left join order_revenue
        on location_month_grid.location_id = order_revenue.location_id
        and location_month_grid.month = order_revenue.month

),

window_calculations as (

    -- Apply window functions for MoM, cumulative, and total calculations
    select
        location_id,
        location_name,
        month,
        monthly_revenue,
        monthly_order_count,
        lag(monthly_revenue) over (
            partition by location_id order by month
        ) as lag_revenue,
        sum(monthly_revenue) over (
            partition by location_id
            order by month
            rows between unbounded preceding and current row
        ) as cumulative_revenue,
        sum(monthly_revenue) over (
            partition by location_id
        ) as location_total_revenue
    from joined_revenue

),

final as (

    -- Compute derived metrics and finalize columns
    select
        location_id,
        location_name,
        month,
        monthly_revenue,
        monthly_order_count,
        (monthly_revenue - lag_revenue)
            / nullif(lag_revenue, 0) * 100 as mom_revenue_growth_pct,
        cumulative_revenue,
        monthly_revenue
            / nullif(location_total_revenue, 0) * 100 as pct_of_location_total
    from window_calculations

)

select * from final
