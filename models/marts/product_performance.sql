{{ config(materialized='table') }}

with

order_items as (

    select * from {{ ref('order_items') }}

),

orders as (

    select * from {{ ref('orders') }}

),

products as (

    select * from {{ ref('products') }}

),

order_items_with_location as (

    select
        order_items.product_id,
        order_items.product_price,
        order_items.supply_cost,
        order_items.order_id,
        orders.location_id

    from order_items

    inner join
        orders
        on order_items.order_id = orders.order_id

),

enriched_with_metadata as (

    select
        order_items_with_location.product_id,
        order_items_with_location.product_price,
        order_items_with_location.supply_cost,
        order_items_with_location.order_id,
        order_items_with_location.location_id,
        products.product_name,
        products.product_type,
        products.product_description

    from order_items_with_location

    inner join
        products
        on order_items_with_location.product_id = products.product_id

),

aggregated as (

    select
        product_id,

        count(*) as total_units_sold,
        sum(product_price) as total_revenue,
        sum(supply_cost) as total_supply_cost,
        sum(product_price) - sum(supply_cost) as gross_profit,
        case
            when sum(product_price) = 0 then null
            else (sum(product_price) - sum(supply_cost)) / sum(product_price)
        end as gross_margin_pct,
        count(distinct order_id) as distinct_order_count,
        count(distinct location_id) as distinct_location_count,
        avg(product_price) as avg_price_per_unit

    from enriched_with_metadata

    group by 1

),

final as (

    select
        aggregated.*,
        products.product_name,
        products.product_type,
        products.product_description,

        row_number() over (
            order by aggregated.total_revenue desc
        ) as revenue_rank

    from aggregated

    inner join
        products
        on aggregated.product_id = products.product_id

)

select
    product_id,
    product_name,
    product_type,
    product_description,
    total_units_sold,
    total_revenue,
    total_supply_cost,
    gross_profit,
    gross_margin_pct,
    distinct_order_count,
    distinct_location_count,
    avg_price_per_unit,
    revenue_rank

from final