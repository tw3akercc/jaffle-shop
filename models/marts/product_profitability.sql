with

products as (

    select * from {{ ref('products') }}

),

order_items as (

    select * from {{ ref('order_items') }}

),

product_sales as (

    select
        product_id,
        count(*) as units_sold,
        count(distinct order_id) as distinct_orders,
        sum(product_price) as pretax_revenue,
        sum(supply_cost) as estimated_cogs

    from order_items

    group by product_id

),

sales_totals as (

    select
        sum(product_price) as total_pretax_revenue,
        count(distinct order_id) as total_orders

    from order_items

),

zero_filled as (

    select
        products.product_id,
        products.product_name,
        products.product_type,
        coalesce(product_sales.units_sold, 0) as units_sold,
        coalesce(product_sales.distinct_orders, 0) as distinct_orders,
        coalesce(product_sales.pretax_revenue, 0) as pretax_revenue,
        coalesce(product_sales.estimated_cogs, 0) as estimated_cogs,
        coalesce(product_sales.pretax_revenue, 0)
            - coalesce(product_sales.estimated_cogs, 0) as gross_profit,
        sales_totals.total_pretax_revenue,
        sales_totals.total_orders

    from products

    left join product_sales
        on products.product_id = product_sales.product_id

    cross join sales_totals

)

select
    product_id,
    product_name,
    product_type,
    units_sold,
    distinct_orders,
    pretax_revenue,
    estimated_cogs,
    gross_profit,
    coalesce(
        {{ dbt_utils.safe_divide('gross_profit', 'pretax_revenue') }},
        0
    ) as gross_margin,
    coalesce(
        {{ dbt_utils.safe_divide('pretax_revenue', 'units_sold') }},
        0
    ) as average_realized_item_revenue,
    coalesce(
        {{ dbt_utils.safe_divide(
            'pretax_revenue',
            'total_pretax_revenue'
        ) }},
        0
    ) as revenue_mix,
    coalesce(
        {{ dbt_utils.safe_divide(
            'distinct_orders * 1.0',
            'total_orders'
        ) }},
        0
    ) as order_penetration

from zero_filled
