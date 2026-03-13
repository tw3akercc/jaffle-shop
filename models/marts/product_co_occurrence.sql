{{ config(materialized='table') }}

with

order_items as (

    select * from {{ ref('order_items') }}

),

products as (

    select * from {{ ref('products') }}

),

-- calculate total distinct orders for support_pct calculation
total_orders as (

    select count(distinct order_id) as total_order_count from order_items

),

-- self-join order_items to create all product pairs within each order
product_pairs as (

    select
        left_items.order_id,
        left_items.product_id as product_id_left,
        right_items.product_id as product_id_right

    from order_items as left_items

    inner join order_items as right_items
        on left_items.order_id = right_items.order_id
        and left_items.product_id < right_items.product_id

),

-- join to products twice to get product details
product_pairs_with_details as (

    select
        product_pairs.order_id,
        product_pairs.product_id_left,
        product_pairs.product_id_right,
        left_products.product_name as product_name_left,
        right_products.product_name as product_name_right,
        left_products.product_type as product_type_left,
        right_products.product_type as product_type_right

    from product_pairs

    left join products as left_products
        on product_pairs.product_id_left = left_products.product_id

    left join products as right_products
        on product_pairs.product_id_right = right_products.product_id

),

-- calculate product order counts (individual product frequency)
product_order_counts as (

    select
        product_id,
        count(distinct order_id) as product_order_count

    from order_items

    group by product_id

),

-- aggregate to unique product pair grain
aggregated as (

    select
        product_pairs_with_details.product_id_left,
        product_pairs_with_details.product_id_right,
        product_pairs_with_details.product_name_left,
        product_pairs_with_details.product_name_right,
        product_pairs_with_details.product_type_left,
        product_pairs_with_details.product_type_right,
        count(distinct product_pairs_with_details.order_id) as co_occurrence_count,
        left_counts.product_order_count as product_left_order_count,
        right_counts.product_order_count as product_right_order_count,
        round(
            100.0 * count(distinct product_pairs_with_details.order_id)
            / nullif(total_orders.total_order_count, 0),
            2
        ) as support_pct

    from product_pairs_with_details

    cross join total_orders

    left join product_order_counts as left_counts
        on product_pairs_with_details.product_id_left = left_counts.product_id

    left join product_order_counts as right_counts
        on product_pairs_with_details.product_id_right = right_counts.product_id

    group by
        product_pairs_with_details.product_id_left,
        product_pairs_with_details.product_id_right,
        product_pairs_with_details.product_name_left,
        product_pairs_with_details.product_name_right,
        product_pairs_with_details.product_type_left,
        product_pairs_with_details.product_type_right,
        left_counts.product_order_count,
        right_counts.product_order_count,
        total_orders.total_order_count

)

select * from aggregated
