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

-- Aggregate order-level metrics separately to avoid duplication
order_metrics as (

    select
        location_id,

        sum(subtotal) as total_revenue,
        sum(tax_paid) as total_tax_collected,
        count(distinct order_id) as order_count,
        round(
            sum(subtotal) / nullif(count(distinct order_id), 0),
            2
        ) as avg_order_value,
        count(distinct customer_id) as unique_customer_count,
        count(distinct case when customer_order_number > 1 then customer_id end)
            as repeat_customer_count,
        min(ordered_at) as first_order_date,
        max(ordered_at) as last_order_date

    from orders

    group by 1

),

-- Calculate proportional item subtotals first
item_subtotals as (

    select
        orders.location_id,
        order_items.supply_cost,
        order_items.is_food_item,
        order_items.is_drink_item,
        orders.subtotal * (order_items.product_price / nullif(sum(order_items.product_price) over (partition by order_items.order_id), 0)) as item_subtotal

    from order_items

    left join orders on order_items.order_id = orders.order_id

),

-- Aggregate item-level metrics to the location level
item_metrics as (

    select
        location_id,

        sum(supply_cost) as total_supply_cost,
        sum(case when is_food_item then item_subtotal end) as food_revenue,
        sum(case when is_drink_item then item_subtotal end) as drink_revenue

    from item_subtotals

    group by 1

),

-- Combine order and item metrics
location_metrics as (

    select
        order_metrics.location_id,

        -- Financial metrics
        order_metrics.total_revenue,
        coalesce(item_metrics.total_supply_cost, 0) as total_supply_cost,
        order_metrics.total_revenue - coalesce(item_metrics.total_supply_cost, 0) as gross_profit,
        round(
            ((order_metrics.total_revenue - coalesce(item_metrics.total_supply_cost, 0)) / nullif(order_metrics.total_revenue, 0)) * 100,
            2
        ) as gross_margin_pct,
        order_metrics.total_tax_collected,

        -- Order metrics
        order_metrics.order_count,
        order_metrics.avg_order_value,

        -- Customer metrics
        order_metrics.unique_customer_count,
        order_metrics.repeat_customer_count,

        -- Product mix revenue
        coalesce(item_metrics.food_revenue, 0) as food_revenue,
        coalesce(item_metrics.drink_revenue, 0) as drink_revenue,

        -- Date range
        order_metrics.first_order_date,
        order_metrics.last_order_date

    from order_metrics

    left join item_metrics on order_metrics.location_id = item_metrics.location_id

),

final as (

    select
        locations.location_id,
        locations.location_name,
        locations.tax_rate,
        locations.opened_date,

        coalesce(location_metrics.total_revenue, 0) as total_revenue,
        coalesce(location_metrics.total_supply_cost, 0) as total_supply_cost,
        coalesce(location_metrics.gross_profit, 0) as gross_profit,
        coalesce(location_metrics.gross_margin_pct, 0) as gross_margin_pct,
        coalesce(location_metrics.total_tax_collected, 0) as total_tax_collected,
        coalesce(location_metrics.order_count, 0) as order_count,
        coalesce(location_metrics.avg_order_value, 0) as avg_order_value,
        coalesce(location_metrics.unique_customer_count, 0) as unique_customer_count,
        coalesce(location_metrics.repeat_customer_count, 0) as repeat_customer_count,
        coalesce(location_metrics.food_revenue, 0) as food_revenue,
        coalesce(location_metrics.drink_revenue, 0) as drink_revenue,
        case
            when coalesce(location_metrics.total_revenue, 0) = 0 then 50
            else round(
                (coalesce(location_metrics.food_revenue, 0)
                    / location_metrics.total_revenue) * 100,
                2
            )
        end as food_revenue_pct,
        case
            when coalesce(location_metrics.total_revenue, 0) = 0 then 50
            else round(
                (coalesce(location_metrics.drink_revenue, 0)
                    / location_metrics.total_revenue) * 100,
                2
            )
        end as drink_revenue_pct,
        location_metrics.first_order_date,
        location_metrics.last_order_date

    from locations

    left join location_metrics
        on locations.location_id = location_metrics.location_id

)

select * from final
