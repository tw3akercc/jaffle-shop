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

product_recipes as (

    select distinct product_id
    from {{ ref('stg_supplies') }}

),

item_reconciliation as (

    select
        order_items.order_id,
        count(order_items.order_item_id) as item_count,
        sum(
            case
                when products.product_id is not null then 1
                else 0
            end
        ) as known_product_count,
        sum(
            case
                when product_recipes.product_id is not null then 1
                else 0
            end
        ) as products_with_recipes,
        coalesce(sum(products.product_price), 0) as calculated_item_subtotal

    from order_items

    left join products
        on order_items.product_id = products.product_id

    left join product_recipes
        on products.product_id = product_recipes.product_id

    group by order_items.order_id

),

reconciliation as (

    select
        orders.order_id,
        orders.subtotal as source_subtotal,
        orders.tax_paid as source_tax,
        orders.order_total as source_total,
        coalesce(item_reconciliation.calculated_item_subtotal, 0)
            as calculated_item_subtotal,
        coalesce(item_reconciliation.item_count, 0) as item_count,
        coalesce(item_reconciliation.known_product_count, 0)
            as known_product_count,
        coalesce(item_reconciliation.products_with_recipes, 0)
            as products_with_recipes

    from orders

    left join item_reconciliation
        on orders.order_id = item_reconciliation.order_id

),

issue_flags as (

    select
        *,
        item_count = 0 as has_no_items,
        known_product_count < item_count as has_unknown_product,
        products_with_recipes < known_product_count
            as has_missing_supply_recipe,
        calculated_item_subtotal != source_subtotal
            as has_subtotal_mismatch,
        source_total != source_subtotal + source_tax
            as has_tax_total_mismatch

    from reconciliation

),

counted_issues as (

    select
        *,
        case when has_no_items then 1 else 0 end
        + case when has_unknown_product then 1 else 0 end
        + case when has_missing_supply_recipe then 1 else 0 end
        + case when has_subtotal_mismatch then 1 else 0 end
        + case when has_tax_total_mismatch then 1 else 0 end as issue_count

    from issue_flags

)

select *
from counted_issues
where issue_count > 0
