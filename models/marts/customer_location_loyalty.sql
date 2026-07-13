with

orders as (

    select * from {{ ref('orders') }}

),

customers as (

    select
        customer_id,
        customer_name

    from {{ ref('customers') }}

),

locations as (

    select
        location_id,
        location_name

    from {{ ref('stg_locations') }}

),

customer_location_orders as (

    select
        customer_id,
        location_id,
        min(cast(ordered_at as date)) as first_order_date,
        max(cast(ordered_at as date)) as last_order_date,
        count(*) as order_count,
        sum(subtotal) as pretax_spend,
        sum(tax_paid) as tax_paid,
        sum(order_total) as total_spend

    from orders

    group by 1, 2

),

customer_totals as (

    select
        *,
        sum(order_count) over (partition by customer_id)
            as customer_order_count,
        sum(total_spend) over (partition by customer_id)
            as customer_total_spend,
        count(*) over (partition by customer_id) as locations_visited

    from customer_location_orders

),

ranked as (

    select
        *,
        row_number() over (
            partition by customer_id
            order by order_count desc, total_spend desc, location_id asc
        ) as location_rank

    from customer_totals

)

select
    ranked.customer_id,
    customers.customer_name,
    ranked.location_id,
    locations.location_name,
    ranked.first_order_date,
    ranked.last_order_date,
    ranked.order_count,
    ranked.pretax_spend,
    ranked.tax_paid,
    ranked.total_spend,
    {{ dbt_utils.safe_divide('ranked.total_spend', 'ranked.order_count') }}
        as average_order_value,
    100.0 * {{ dbt_utils.safe_divide(
        'ranked.order_count',
        'ranked.customer_order_count'
    ) }} as percentage_of_customer_orders,
    100.0 * {{ dbt_utils.safe_divide(
        'ranked.total_spend',
        'ranked.customer_total_spend'
    ) }} as percentage_of_customer_spend,
    ranked.location_rank,
    ranked.location_rank = 1 as is_primary_location,
    ranked.locations_visited

from ranked

inner join customers on ranked.customer_id = customers.customer_id

inner join locations on ranked.location_id = locations.location_id
