{{ config(materialized='table') }}

with

orders as (

    select * from {{ ref('orders') }}

),

locations as (

    select * from {{ ref('locations') }}

),

monthly_orders as (

    select
        orders.location_id,
        locations.location_name,
        {{ dbt.date_trunc('month', 'orders.ordered_at') }} as month,
        count(orders.order_id) as monthly_order_count,
        sum(orders.subtotal) as monthly_subtotal,
        sum(orders.order_total) as monthly_order_total

    from orders

    left join locations
        on orders.location_id = locations.location_id

    group by
        orders.location_id,
        locations.location_name,
        {{ dbt.date_trunc('month', 'orders.ordered_at') }}

),

with_mom_growth as (

    select
        location_id,
        location_name,
        month,
        monthly_order_count,
        monthly_subtotal,
        monthly_order_total,
        (
            monthly_subtotal
            - lag(monthly_subtotal) over (
                partition by location_id order by month
            )
        ) / nullif(
            lag(monthly_subtotal) over (
                partition by location_id order by month
            ),
            0
        ) as mom_subtotal_growth_pct,
        (
            monthly_order_total
            - lag(monthly_order_total) over (
                partition by location_id order by month
            )
        ) / nullif(
            lag(monthly_order_total) over (
                partition by location_id order by month
            ),
            0
        ) as mom_order_total_growth_pct

    from monthly_orders

),

with_cumulative as (

    select
        location_id,
        location_name,
        month,
        monthly_order_count,
        monthly_subtotal,
        monthly_order_total,
        mom_subtotal_growth_pct,
        mom_order_total_growth_pct,
        sum(monthly_subtotal) over (
            partition by location_id
            order by month
            rows between unbounded preceding and current row
        ) as cumulative_subtotal,
        sum(monthly_order_total) over (
            partition by location_id
            order by month
            rows between unbounded preceding and current row
        ) as cumulative_order_total

    from with_mom_growth

),

final as (

    select
        location_id,
        location_name,
        month,
        monthly_order_count,
        monthly_subtotal,
        monthly_order_total,
        mom_subtotal_growth_pct,
        mom_order_total_growth_pct,
        cumulative_subtotal,
        cumulative_order_total,
        monthly_subtotal / sum(monthly_subtotal) over (
            partition by location_id
        ) as pct_of_total_subtotal,
        monthly_order_total / sum(monthly_order_total) over (
            partition by location_id
        ) as pct_of_total_order_total

    from with_cumulative

)

select * from final
