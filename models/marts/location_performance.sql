{{ config(materialized='table') }}

with

orders as (

    select * from {{ ref('orders') }}

),

order_items as (

    select * from {{ ref('order_items') }}

),

locations as (

    select * from {{ ref('locations') }}

),

order_metrics as (

    select
        location_id,

        sum(order_total) as total_revenue,
        sum(order_cost) as total_supply_cost,
        sum(order_total) - sum(order_cost) as gross_profit,
        (
            sum(order_total) - sum(order_cost)
        ) / nullif(sum(order_total), 0) * 100 as gross_margin_pct,
        count(*) as order_count,
        sum(order_total) / nullif(count(*), 0) as avg_order_value,
        count(distinct customer_id) as unique_customer_count,
        count(
            distinct case
                when customer_order_number > 1 then customer_id
            end
        ) as repeat_customer_count,
        min(ordered_at) as first_order_date,
        max(ordered_at) as last_order_date

    from orders

    group by 1

),

food_drink_revenue as (

    select
        orders.location_id,

        sum(
            case
                when order_items.is_food_item
                then order_items.product_price
                else 0
            end
        ) as food_revenue,

        sum(
            case
                when order_items.is_drink_item
                then order_items.product_price
                else 0
            end
        ) as drink_revenue

    from orders

    left join order_items
        on orders.order_id = order_items.order_id

    group by 1

),

joined as (

    select
        order_metrics.*,

        food_drink_revenue.food_revenue,
        food_drink_revenue.drink_revenue,
        food_drink_revenue.food_revenue / nullif(
            food_drink_revenue.food_revenue + food_drink_revenue.drink_revenue, 0
        ) * 100 as food_revenue_pct,
        food_drink_revenue.drink_revenue / nullif(
            food_drink_revenue.food_revenue + food_drink_revenue.drink_revenue, 0
        ) * 100 as drink_revenue_pct

    from order_metrics

    left join food_drink_revenue
        on order_metrics.location_id = food_drink_revenue.location_id

),

final as (

    select
        joined.*,

        locations.location_name,
        locations.tax_rate,
        locations.opened_date

    from joined

    left join locations
        on joined.location_id = locations.location_id

)

select * from final
