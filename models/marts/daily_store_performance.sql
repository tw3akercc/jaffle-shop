with

locations as (

    select
        location_id,
        location_name,
        cast(opened_date as date) as opened_date

    from {{ ref('stg_locations') }}

),

date_offsets as (

    {{ dbt_utils.generate_series(upper_bound=366000) }}

),

location_date_spine as (

    select
        locations.location_id,
        locations.location_name,
        cast(
            {{ dbt.dateadd(
                'day',
                'date_offsets.generated_number - 1',
                'locations.opened_date'
            ) }}
            as date
        ) as order_date

    from locations

    cross join date_offsets

    where
        locations.opened_date <= {{ dbt_date.today('America/Los_Angeles') }}
        and {{ dbt.dateadd(
            'day',
            'date_offsets.generated_number - 1',
            'locations.opened_date'
        ) }} <= {{ dbt_date.today('America/Los_Angeles') }}

),

orders as (

    select * from {{ ref('orders') }}

),

daily_orders as (

    select
        location_id,
        cast(ordered_at as date) as order_date,
        count(*) as order_count,
        count(distinct customer_id) as unique_customers,
        sum(case when customer_order_number = 1 then 1 else 0 end)
            as new_customer_orders,
        sum(case when customer_order_number > 1 then 1 else 0 end)
            as repeat_customer_orders,
        sum(order_total) as gross_revenue,
        sum(subtotal) as pretax_revenue,
        sum(tax_paid) as tax_paid,
        sum(order_cost) as supply_cost,
        sum(count_food_items) as food_item_count,
        sum(count_drink_items) as drink_item_count

    from orders

    group by 1, 2

),

order_items as (

    select * from {{ ref('order_items') }}

),

daily_item_revenue as (

    select
        orders.location_id,
        cast(order_items.ordered_at as date) as order_date,
        sum(
            case
                when order_items.is_food_item then order_items.product_price
                else 0
            end
        ) as food_revenue,
        sum(
            case
                when order_items.is_drink_item then order_items.product_price
                else 0
            end
        ) as drink_revenue

    from order_items

    inner join orders on order_items.order_id = orders.order_id

    group by 1, 2

),

zero_filled as (

    select
        location_date_spine.location_id,
        location_date_spine.location_name,
        location_date_spine.order_date,
        coalesce(daily_orders.order_count, 0) as order_count,
        coalesce(daily_orders.unique_customers, 0) as unique_customers,
        coalesce(daily_orders.new_customer_orders, 0) as new_customer_orders,
        coalesce(daily_orders.repeat_customer_orders, 0)
            as repeat_customer_orders,
        coalesce(daily_orders.gross_revenue, 0) as gross_revenue,
        coalesce(daily_orders.pretax_revenue, 0) as pretax_revenue,
        coalesce(daily_orders.tax_paid, 0) as tax_paid,
        coalesce(daily_orders.supply_cost, 0) as supply_cost,
        coalesce(daily_orders.pretax_revenue, 0)
            - coalesce(daily_orders.supply_cost, 0) as gross_profit,
        coalesce(daily_orders.food_item_count, 0) as food_item_count,
        coalesce(daily_orders.drink_item_count, 0) as drink_item_count,
        coalesce(daily_item_revenue.food_revenue, 0) as food_revenue,
        coalesce(daily_item_revenue.drink_revenue, 0) as drink_revenue

    from location_date_spine

    left join daily_orders
        on location_date_spine.location_id = daily_orders.location_id
        and location_date_spine.order_date = daily_orders.order_date

    left join daily_item_revenue
        on location_date_spine.location_id = daily_item_revenue.location_id
        and location_date_spine.order_date = daily_item_revenue.order_date

)

select
    location_id,
    location_name,
    order_date,
    order_count,
    unique_customers,
    new_customer_orders,
    repeat_customer_orders,
    gross_revenue,
    pretax_revenue,
    tax_paid,
    supply_cost,
    gross_profit,
    100.0 * {{ dbt_utils.safe_divide('gross_profit', 'pretax_revenue') }}
        as gross_margin_percentage,
    food_item_count,
    drink_item_count,
    food_revenue,
    drink_revenue

from zero_filled
