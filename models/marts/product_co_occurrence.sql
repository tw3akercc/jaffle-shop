{{ config(materialized='table') }}

with

order_items as (

    select * from {{ ref('order_items') }}

),

products as (

    select * from {{ ref('products') }}

),

-- Get total distinct orders for support calculation
order_totals as (

    select
        count(distinct order_id) as total_orders

    from order_items

),

-- Self-join to find all product pairs within the same order
-- Use product_id_left < product_id_right to ensure unique unordered pairs
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

-- Join to products to get product names
enriched_pairs as (

    select
        product_pairs.order_id,
        product_pairs.product_id_left,
        product_pairs.product_id_right,
        left_products.product_name as product_name_left,
        right_products.product_name as product_name_right

    from product_pairs

    inner join products as left_products
        on product_pairs.product_id_left = left_products.product_id

    inner join products as right_products
        on product_pairs.product_id_right = right_products.product_id

),

-- Calculate co-occurrence counts
-- Also calculate individual product frequencies
aggregated as (

    select
        product_id_left,
        product_id_right,
        product_name_left,
        product_name_right,
        count(distinct order_id) as co_occurrence_count

    from enriched_pairs

    group by
        product_id_left,
        product_id_right,
        product_name_left,
        product_name_right

),

-- Calculate individual product frequencies
product_frequencies as (

    select
        product_id,
        count(distinct order_id) as order_frequency

    from order_items

    group by product_id

),

-- Add individual frequencies to the pairs
with_frequencies as (

    select
        aggregated.product_id_left,
        aggregated.product_id_right,
        aggregated.product_name_left,
        aggregated.product_name_right,
        aggregated.co_occurrence_count,
        left_freq.order_frequency as product_left_frequency,
        right_freq.order_frequency as product_right_frequency

    from aggregated

    inner join product_frequencies as left_freq
        on aggregated.product_id_left = left_freq.product_id

    inner join product_frequencies as right_freq
        on aggregated.product_id_right = right_freq.product_id

),

-- Calculate support (percentage of all orders containing both products)
final as (

    select
        product_id_left,
        product_id_right,
        product_name_left,
        product_name_right,
        co_occurrence_count,
        product_left_frequency,
        product_right_frequency,
        round(
            co_occurrence_count * 100.0 / order_totals.total_orders,
            2
        ) as support

    from with_frequencies

    cross join order_totals

)

select * from final
