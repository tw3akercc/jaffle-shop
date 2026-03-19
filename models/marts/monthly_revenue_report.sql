{{ config(materialized='table') }}

with

orders as (

    select * from {{ ref('orders') }}

),

locations as (

    select * from {{ ref('locations') }}

),

monthly_revenue as (

    -- aggregate to location × month grain
    select
        location_id,
        {{ dbt.date_trunc('month', 'ordered_at') }} as revenue_month,
        sum(subtotal) as revenue,
        count(order_id) as order_count
    from orders
    group by 1, 2

),

with_windows as (

    -- apply window functions for growth, cumulative, and all-time totals
    select
        location_id,
        revenue_month,
        revenue,
        order_count,
        lag(revenue, 1) over (
            partition by location_id order by revenue_month
        ) as prior_month_revenue,
        sum(revenue) over (
            partition by location_id order by revenue_month
            rows between unbounded preceding and current row
        ) as cumulative_revenue,
        sum(revenue) over (
            partition by location_id
        ) as location_total_revenue
    from monthly_revenue

),

final as (

    select
        ---------- ids
        w.location_id,
        l.location_name,

        ---------- time
        w.revenue_month,

        ---------- numerics
        w.revenue,
        w.order_count,
        (w.revenue - w.prior_month_revenue) / w.prior_month_revenue * 100 as revenue_mom_growth_pct,
        w.cumulative_revenue,
        w.revenue / w.location_total_revenue * 100 as pct_of_location_total_revenue
    from with_windows w
    left join locations l on w.location_id = l.location_id

)

select * from final
