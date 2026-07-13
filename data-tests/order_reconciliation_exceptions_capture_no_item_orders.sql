with

expected_no_item_orders as (

    select orders.order_id
    from {{ ref('stg_orders') }} as orders

    left join {{ ref('stg_order_items') }} as order_items
        on orders.order_id = order_items.order_id

    group by orders.order_id
    having count(order_items.order_item_id) = 0

),

actual_no_item_orders as (

    select order_id
    from {{ ref('order_reconciliation_exceptions') }}
    where has_no_items

),

missing_from_mart as (

    select expected_no_item_orders.order_id
    from expected_no_item_orders

    left join actual_no_item_orders
        on expected_no_item_orders.order_id = actual_no_item_orders.order_id

    where actual_no_item_orders.order_id is null

),

unexpected_in_mart as (

    select actual_no_item_orders.order_id
    from actual_no_item_orders

    left join expected_no_item_orders
        on actual_no_item_orders.order_id = expected_no_item_orders.order_id

    where expected_no_item_orders.order_id is null

)

select * from missing_from_mart
union all
select * from unexpected_in_mart
