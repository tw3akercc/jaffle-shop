with

product_profitability as (

    select * from {{ ref('product_profitability') }}

),

order_items as (

    select * from {{ ref('order_items') }}

),

products as (

    select * from {{ ref('products') }}

),

product_totals as (

    select
        count(*) as product_count,
        sum(units_sold) as units_sold,
        sum(pretax_revenue) as pretax_revenue,
        sum(estimated_cogs) as estimated_cogs

    from product_profitability

),

order_item_totals as (

    select
        count(*) as units_sold,
        sum(product_price) as pretax_revenue,
        sum(supply_cost) as estimated_cogs

    from order_items

),

catalog_totals as (

    select count(*) as product_count

    from products

)

select 1 as reconciliation_failure

from product_totals

cross join order_item_totals

cross join catalog_totals

where
    product_totals.product_count != catalog_totals.product_count
    or product_totals.units_sold != order_item_totals.units_sold
    or product_totals.pretax_revenue != order_item_totals.pretax_revenue
    or product_totals.estimated_cogs != order_item_totals.estimated_cogs
