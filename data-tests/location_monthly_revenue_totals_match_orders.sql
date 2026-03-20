-- This test verifies that the total sum of monthly_revenue in location_monthly_revenue
-- equals the total sum of order_total in orders. This confirms that:
-- 1. Zero-fill rows add nothing to the total
-- 2. No orders are double-counted or dropped
-- 3. The aggregation logic is correct

with

orders_source as (

    select sum(order_total) as total_order_revenue
    from {{ ref('orders') }}

),

monthly_revenue_agg as (

    select sum(monthly_revenue) as total_monthly_revenue
    from {{ ref('location_monthly_revenue') }}

),

comparison as (

    select
        orders_source.total_order_revenue,
        monthly_revenue_agg.total_monthly_revenue,
        orders_source.total_order_revenue - monthly_revenue_agg.total_monthly_revenue as difference

    from orders_source

    cross join monthly_revenue_agg

)

select *
from comparison
where difference != 0
