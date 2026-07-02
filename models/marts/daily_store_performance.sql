with

orders as (

    select
        order_id,
        location_id,
        customer_id,
        cast(ordered_at as date) as ordered_at,
        customer_order_number,
        order_total,
        subtotal,
        tax_paid,
        order_cost,
        count_food_items,
        count_drink_items

    from {{ ref('orders') }}

),

order_aggregate as (

    select
        location_id,
        ordered_at,

        count(distinct order_id) as order_count,
        count(distinct customer_id) as unique_customers,
        sum(
            case
                when customer_order_number = 1 then 1
                else 0
            end
        ) as new_customer_orders,
        sum(
            case
                when customer_order_number > 1 then 1
                else 0
            end
        ) as repeat_customer_orders,
        sum(order_total) as gross_revenue,
        sum(subtotal) as pretax_revenue,
        sum(tax_paid) as tax_paid,
        sum(order_cost) as supply_cost,
        sum(count_food_items) as food_item_count,
        sum(count_drink_items) as drink_item_count

    from orders

    group by 1, 2

)

select * from order_aggregate
