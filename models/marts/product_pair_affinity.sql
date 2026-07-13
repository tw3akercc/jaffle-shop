with

distinct_basket_products as (

    select distinct
        order_id,
        product_id

    from {{ ref('stg_order_items') }}

),

basket_count as (

    select count(distinct order_id) as total_orders

    from distinct_basket_products

),

product_order_counts as (

    select
        product_id,
        count(*) as product_orders

    from distinct_basket_products

    group by product_id

),

pair_order_counts as (

    select
        product_a.product_id as product_a_id,
        product_b.product_id as product_b_id,
        count(*) as orders_containing_both

    from distinct_basket_products as product_a

    inner join distinct_basket_products as product_b
        on product_a.order_id = product_b.order_id
        and product_a.product_id < product_b.product_id

    group by
        product_a.product_id,
        product_b.product_id

),

pair_metrics as (

    select
        pair_order_counts.product_a_id,
        product_a.product_name as product_a_name,
        product_a.product_type as product_a_type,
        pair_order_counts.product_b_id,
        product_b.product_name as product_b_name,
        product_b.product_type as product_b_type,
        pair_order_counts.orders_containing_both,
        product_a_counts.product_orders as product_a_orders,
        product_b_counts.product_orders as product_b_orders,
        pair_order_counts.orders_containing_both * 1.0
            / nullif(basket_count.total_orders, 0) as support,
        pair_order_counts.orders_containing_both * 1.0
            / nullif(product_a_counts.product_orders, 0) as confidence_a_to_b,
        pair_order_counts.orders_containing_both * 1.0
            / nullif(product_b_counts.product_orders, 0) as confidence_b_to_a,
        (
            pair_order_counts.orders_containing_both * 1.0
            * basket_count.total_orders
        ) / nullif(
            product_a_counts.product_orders
            * 1.0
            * product_b_counts.product_orders,
            0
        ) as lift,
        case
            when product_a.is_food_item and product_b.is_food_item
                then 'food-food'
            when product_a.is_drink_item and product_b.is_drink_item
                then 'drink-drink'
            else 'food-drink'
        end as pair_classification

    from pair_order_counts

    inner join {{ ref('stg_products') }} as product_a
        on pair_order_counts.product_a_id = product_a.product_id

    inner join {{ ref('stg_products') }} as product_b
        on pair_order_counts.product_b_id = product_b.product_id

    inner join product_order_counts as product_a_counts
        on pair_order_counts.product_a_id = product_a_counts.product_id

    inner join product_order_counts as product_b_counts
        on pair_order_counts.product_b_id = product_b_counts.product_id

    cross join basket_count

),

ranked as (

    select
        *,
        row_number() over (
            order by
                orders_containing_both desc,
                lift desc,
                product_a_id,
                product_b_id
        ) as pair_rank

    from pair_metrics

)

select * from ranked
