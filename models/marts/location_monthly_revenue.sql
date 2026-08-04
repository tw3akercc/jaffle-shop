with

orders as (

    select * from {{ ref('orders') }}

),

locations as (

    select * from {{ ref('locations') }}

),

monthly_orders as (

    select
        location_id,
        {{ dbt.date_trunc('month', 'ordered_at') }} as month,
        count(order_id) as order_count,
        cast(sum(subtotal) as numeric(16, 2)) as monthly_subtotal,
        cast(sum(order_total) as numeric(16, 2)) as monthly_order_total

    from orders

    group by 1, 2

),

with_location as (

    select
        monthly_orders.location_id,
        locations.location_name,
        monthly_orders.month,
        monthly_orders.order_count,
        monthly_orders.monthly_subtotal,
        monthly_orders.monthly_order_total

    from monthly_orders

    left join locations
        on monthly_orders.location_id = locations.location_id

),

final as (

    select
        location_id,
        location_name,
        month,
        order_count,
        monthly_subtotal,
        monthly_order_total,

        -- month-over-month growth
        round(
            (
                monthly_subtotal
                - lag(monthly_subtotal) over (
                    partition by location_id order by month
                )
            )
            / nullif(
                lag(monthly_subtotal) over (
                    partition by location_id order by month
                ),
                0
            ) * 100,
            2
        ) as mom_subtotal_growth_pct,

        round(
            (
                monthly_order_total
                - lag(monthly_order_total) over (
                    partition by location_id order by month
                )
            )
            / nullif(
                lag(monthly_order_total) over (
                    partition by location_id order by month
                ),
                0
            ) * 100,
            2
        ) as mom_order_total_growth_pct,

        -- running cumulative totals
        cast(
            sum(monthly_subtotal) over (
                partition by location_id
                order by month
                rows between unbounded preceding and current row
            ) as numeric(16, 2)
        ) as cumulative_subtotal,

        cast(
            sum(monthly_order_total) over (
                partition by location_id
                order by month
                rows between unbounded preceding and current row
            ) as numeric(16, 2)
        ) as cumulative_order_total,

        -- percentage of all-time location revenue
        round(
            monthly_subtotal
            / nullif(
                sum(monthly_subtotal) over (partition by location_id),
                0
            ) * 100,
            2
        ) as pct_of_total_subtotal,

        round(
            monthly_order_total
            / nullif(
                sum(monthly_order_total) over (partition by location_id),
                0
            ) * 100,
            2
        ) as pct_of_total_order_total

    from with_location

)

select * from final
