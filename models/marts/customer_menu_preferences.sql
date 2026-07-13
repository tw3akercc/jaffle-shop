with

customers as (

    select * from {{ ref('stg_customers') }}

),

order_items as (

    select * from {{ ref('stg_order_items') }}

),

orders as (

    select * from {{ ref('stg_orders') }}

),

products as (

    select * from {{ ref('stg_products') }}

),

purchased_items as (

    select
        orders.customer_id,
        order_items.product_id,
        products.product_name,
        products.product_price,
        products.is_food_item,
        products.is_drink_item

    from order_items

    inner join orders on order_items.order_id = orders.order_id

    left join products on order_items.product_id = products.product_id

),

product_preferences as (

    select
        customer_id,
        product_id,
        product_name,
        count(*) as product_units,
        sum(product_price) as product_revenue

    from purchased_items

    group by 1, 2, 3

),

ranked_product_preferences as (

    select
        *,
        row_number() over (
            partition by customer_id
            order by
                product_units desc,
                product_revenue desc,
                product_id asc
        ) as product_preference_rank

    from product_preferences

),

favorite_products as (

    select *

    from ranked_product_preferences

    where product_preference_rank = 1

),

customer_item_summaries as (

    select
        customer_id,
        count(*) as lifetime_item_count,
        count(distinct product_id) as distinct_product_count,
        sum(case when is_food_item then 1 else 0 end) as food_item_count,
        sum(case when is_drink_item then 1 else 0 end) as drink_item_count,
        sum(case when is_food_item then product_price else 0 end)
            as food_item_revenue,
        sum(case when is_drink_item then product_price else 0 end)
            as drink_item_revenue

    from purchased_items

    group by 1

),

joined as (

    select
        customers.customer_id,
        customers.customer_name,
        coalesce(customer_item_summaries.lifetime_item_count, 0)
            as lifetime_item_count,
        coalesce(customer_item_summaries.distinct_product_count, 0)
            as distinct_product_count,
        coalesce(customer_item_summaries.food_item_count, 0)
            as food_item_count,
        coalesce(customer_item_summaries.drink_item_count, 0)
            as drink_item_count,
        coalesce(customer_item_summaries.food_item_revenue, 0)
            as food_item_revenue,
        coalesce(customer_item_summaries.drink_item_revenue, 0)
            as drink_item_revenue,
        coalesce(
            {{ dbt_utils.safe_divide(
                '1.0 * customer_item_summaries.food_item_count',
                'customer_item_summaries.lifetime_item_count'
            ) }},
            0
        ) as food_item_share,
        coalesce(
            {{ dbt_utils.safe_divide(
                '1.0 * customer_item_summaries.drink_item_count',
                'customer_item_summaries.lifetime_item_count'
            ) }},
            0
        ) as drink_item_share,
        case
            when customer_item_summaries.lifetime_item_count is null
                then 'no purchases'
            when customer_item_summaries.food_item_count
                > customer_item_summaries.drink_item_count
                then 'food'
            when customer_item_summaries.drink_item_count
                > customer_item_summaries.food_item_count
                then 'drink'
            when customer_item_summaries.food_item_revenue
                >= customer_item_summaries.drink_item_revenue
                then 'food'
            else 'drink'
        end as preferred_product_type,
        favorite_products.product_id as favorite_product_id,
        favorite_products.product_name as favorite_product_name,
        coalesce(favorite_products.product_units, 0) as favorite_product_units,
        coalesce(favorite_products.product_revenue, 0)
            as favorite_product_revenue,
        coalesce(
            {{ dbt_utils.safe_divide(
                '1.0 * favorite_products.product_units',
                'customer_item_summaries.lifetime_item_count'
            ) }},
            0
        ) as favorite_product_share

    from customers

    left join customer_item_summaries
        on customers.customer_id = customer_item_summaries.customer_id

    left join favorite_products
        on customers.customer_id = favorite_products.customer_id

)

select * from joined
