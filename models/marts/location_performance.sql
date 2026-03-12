{{ config(materialized='table') }}

with

locations as (

    select * from {{ ref('locations') }}

),

orders as (

    select * from {{ ref('orders') }}

),

order_items as (

    select * from {{ ref('order_items') }}

),

-- Join orders to order_items to get item-level details
orders_with_items as (

    select
        orders.order_id,
        orders.location_id,
        orders.customer_id,
        orders.subtotal,
        orders.tax_paid,
        orders.ordered_at,
        orders.customer_order_number,

        order_items.product_price,
        order_items.supply_cost,
        order_items.is_food_item,
        order_items.is_drink_item

    from orders

    left join order_items on orders.order_id = order_items.order_id

),

-- Calculate order-level item summaries to determine food/drink proportions
order_item_summary as (

    select
        order_id,

        sum(product_price) as total_product_price,
        sum(
            case
                when is_food_item then product_price
                else 0
            end
        ) as food_product_price,
        sum(
            case
                when is_drink_item then product_price
                else 0
            end
        ) as drink_product_price

    from order_items

    group by 1

),

-- Join order summaries back to orders to calculate proportional revenue
orders_with_proportions as (

    select
        orders.order_id,
        orders.location_id,
        orders.customer_id,
        orders.subtotal,
        orders.tax_paid,
        orders.ordered_at,
        orders.customer_order_number,

        -- Calculate proportional revenue based on item price proportions
        case
            when order_item_summary.total_product_price > 0 then
                orders.subtotal * (order_item_summary.food_product_price / order_item_summary.total_product_price)
            else 0
        end as food_revenue,
        case
            when order_item_summary.total_product_price > 0 then
                orders.subtotal * (order_item_summary.drink_product_price / order_item_summary.total_product_price)
            else 0
        end as drink_revenue

    from orders

    left join order_item_summary on orders.order_id = order_item_summary.order_id

),

-- Aggregate metrics at the location level
location_metrics as (

    select
        location_id,

        -- Financial metrics
        sum(subtotal) as total_revenue,
        sum(tax_paid) as total_tax_collected,
        sum(food_revenue) as food_revenue,
        sum(drink_revenue) as drink_revenue,

        -- Food and drink revenue percentages
        case
            when sum(subtotal) > 0 then
                round((sum(food_revenue) / sum(subtotal)) * 100, 2)
            else 0
        end as food_revenue_pct,
        case
            when sum(subtotal) > 0 then
                round((sum(drink_revenue) / sum(subtotal)) * 100, 2)
            else 0
        end as drink_revenue_pct,

        -- Order metrics
        count(distinct order_id) as order_count,
        case
            when count(distinct order_id) > 0 then
                round(sum(subtotal) / count(distinct order_id), 2)
            else 0
        end as avg_order_value,

        -- Customer metrics
        count(distinct customer_id) as unique_customer_count,
        count(
            distinct case
                when customer_order_number > 1 then customer_id
            end
        ) as repeat_customer_count,

        -- Date range
        min(ordered_at) as first_order_date,
        max(ordered_at) as last_order_date

    from orders_with_proportions

    group by 1

),

-- Join order metrics to all locations
final as (

    select
        locations.location_id,
        locations.location_name,
        locations.tax_rate,
        locations.opened_date,

        coalesce(location_metrics.total_revenue, 0) as total_revenue,
        coalesce(location_metrics.total_tax_collected, 0) as total_tax_collected,
        coalesce(location_metrics.food_revenue, 0) as food_revenue,
        coalesce(location_metrics.drink_revenue, 0) as drink_revenue,
        coalesce(location_metrics.food_revenue_pct, 0) as food_revenue_pct,
        coalesce(location_metrics.drink_revenue_pct, 0) as drink_revenue_pct,
        coalesce(location_metrics.order_count, 0) as order_count,
        coalesce(location_metrics.avg_order_value, 0) as avg_order_value,
        coalesce(location_metrics.unique_customer_count, 0) as unique_customer_count,
        coalesce(location_metrics.repeat_customer_count, 0) as repeat_customer_count,
        location_metrics.first_order_date,
        location_metrics.last_order_date,

        -- Calculate supply cost and gross profit in the final select
        coalesce(supply_costs.total_supply_cost, 0) as total_supply_cost,
        coalesce(location_metrics.total_revenue, 0) - coalesce(supply_costs.total_supply_cost, 0) as gross_profit,
        case
            when coalesce(location_metrics.total_revenue, 0) > 0 then
                round(
                    ((coalesce(location_metrics.total_revenue, 0) - coalesce(supply_costs.total_supply_cost, 0))
                     / location_metrics.total_revenue) * 100,
                    2
                )
            else 0
        end as gross_margin_pct

    from locations

    left join location_metrics on locations.location_id = location_metrics.location_id

    left join (
        select
            o.location_id,
            sum(oi.supply_cost) as total_supply_cost
        from orders o
        left join order_items oi on o.order_id = oi.order_id
        group by 1
    ) as supply_costs on locations.location_id = supply_costs.location_id

)

select * from final
