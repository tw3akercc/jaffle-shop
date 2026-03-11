{{ config(materialized='table') }}

with

orders as (

    select * from {{ ref('stg_orders') }}

),

order_items as (

    select * from {{ ref('stg_order_items') }}

),

products as (

    select * from {{ ref('stg_products') }}

),

supplies as (

    select * from {{ ref('stg_supplies') }}

),

order_supplies as (

    select
        product_id,

        sum(supply_cost) as supply_cost

    from supplies

    group by 1

),

order_items_enriched as (

    select
        order_items.*,

        orders.ordered_at,
        orders.customer_id,
        orders.order_total,

        products.product_price,
        products.is_food_item,
        products.is_drink_item,

        order_supplies.supply_cost

    from order_items

    left join orders on order_items.order_id = orders.order_id

    left join products on order_items.product_id = products.product_id

    left join order_supplies on order_items.product_id = order_supplies.product_id

),

line_level_metrics as (

    select
        order_id,
        location_id,
        customer_id,
        ordered_at,
        order_total,

        product_price * 1 as line_revenue,
        coalesce(supply_cost, 0) * 1 as line_cost,

        case
            when is_food_item then product_price * 1
            else 0
        end as food_revenue,

        case
            when is_drink_item then product_price * 1
            else 0
        end as drink_revenue

    from order_items_enriched

),

location_metrics as (

    select
        location_id,

        sum(order_total) as total_revenue,
        sum(line_cost) as total_supply_cost,
        count(distinct order_id) as order_count,
        count(distinct customer_id) as unique_customer_count,
        min(ordered_at) as first_order_date,
        max(ordered_at) as last_order_date,
        sum(food_revenue) as food_revenue,
        sum(drink_revenue) as drink_revenue

    from line_level_metrics

    group by 1

),

customer_order_counts as (

    select
        location_id,
        customer_id,

        count(*) as order_count_at_location

    from line_level_metrics

    group by 1, 2

),

repeat_customers as (

    select
        location_id,

        count(*) as repeat_customer_count

    from customer_order_counts

    where order_count_at_location > 1

    group by 1

),

final as (

    select
        location_metrics.location_id,
        locations.location_name,
        locations.tax_rate,
        locations.opened_date,
        location_metrics.total_revenue,
        location_metrics.total_supply_cost,
        location_metrics.total_revenue - location_metrics.total_supply_cost as gross_profit,
        (location_metrics.total_revenue - location_metrics.total_supply_cost) / nullif(location_metrics.total_revenue, 0) * 100 as gross_margin_percentage,
        location_metrics.order_count,
        location_metrics.total_revenue / nullif(location_metrics.order_count, 0) as average_order_value,
        location_metrics.unique_customer_count,
        coalesce(repeat_customers.repeat_customer_count, 0) as repeat_customer_count,
        location_metrics.food_revenue,
        location_metrics.drink_revenue,
        location_metrics.food_revenue / nullif(location_metrics.total_revenue, 0) * 100 as food_revenue_pct,
        location_metrics.drink_revenue / nullif(location_metrics.total_revenue, 0) * 100 as drink_revenue_pct,
        location_metrics.first_order_date,
        location_metrics.last_order_date

    from location_metrics

    left join {{ ref('locations') }} as locations on location_metrics.location_id = locations.location_id

    left join repeat_customers on location_metrics.location_id = repeat_customers.location_id

)

select * from final
