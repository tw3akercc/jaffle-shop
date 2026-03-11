{{ config(materialized='table') }}

with

orders as (

    select * from {{ ref('orders') }}

),

order_items as (

    select * from {{ ref('order_items') }}

),

customers as (

    select * from {{ ref('customers') }}

),

order_items_by_order as (

    select
        order_id,

        sum(quantity) as total_quantity,
        sum(
            case
                when is_food_item then quantity
                else 0
            end
        ) as food_quantity,
        sum(
            case
                when is_drink_item then quantity
                else 0
            end
        ) as drink_quantity

    from order_items

    group by 1

),

orders_with_items as (

    select
        orders.order_id,
        orders.customer_id,
        orders.ordered_at,
        orders.subtotal,

        coalesce(order_items_by_order.total_quantity, 0) as daily_item_count,
        coalesce(order_items_by_order.food_quantity, 0) as daily_food_items,
        coalesce(order_items_by_order.drink_quantity, 0) as daily_drink_items

    from orders

    left join order_items_by_order
        on orders.order_id = order_items_by_order.order_id

),

daily_aggregated as (

    select
        customer_id,
        ordered_at as order_date,

        count(distinct order_id) as daily_order_count,
        sum(subtotal) as daily_subtotal,
        sum(daily_item_count) as daily_item_count,
        sum(daily_food_items) as daily_food_items,
        sum(daily_drink_items) as daily_drink_items

    from orders_with_items

    group by 1, 2

),

customer_first_order as (

    select
        customer_id,
        min(order_date) as first_order_date

    from daily_aggregated

    group by 1

),

with_cumulative as (

    select
        daily_aggregated.*,
        customers.customer_name,
        customer_first_order.first_order_date,

        sum(daily_subtotal) over (
            partition by daily_aggregated.customer_id
            order by order_date
            rows between unbounded preceding and current row
        ) as cumulative_lifetime_spend,

        sum(daily_order_count) over (
            partition by daily_aggregated.customer_id
            order by order_date
            rows between unbounded preceding and current row
        ) as cumulative_lifetime_orders,

        case
            when daily_aggregated.order_date = customer_first_order.first_order_date then true
            else false
        end as is_first_order_day

    from daily_aggregated

    left join customers
        on daily_aggregated.customer_id = customers.customer_id

    left join customer_first_order
        on daily_aggregated.customer_id = customer_first_order.customer_id

)

select
    customer_id,
    order_date,
    customer_name,
    daily_order_count,
    daily_subtotal,
    daily_item_count,
    daily_food_items,
    daily_drink_items,
    cumulative_lifetime_spend,
    cumulative_lifetime_orders,
    is_first_order_day

from with_cumulative
