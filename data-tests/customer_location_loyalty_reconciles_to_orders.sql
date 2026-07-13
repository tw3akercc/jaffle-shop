with

orders_by_customer_location as (

    select
        customer_id,
        location_id,
        min(cast(ordered_at as date)) as first_order_date,
        max(cast(ordered_at as date)) as last_order_date,
        count(*) as order_count,
        sum(subtotal) as pretax_spend,
        sum(tax_paid) as tax_paid,
        sum(order_total) as total_spend

    from {{ ref('orders') }}

    group by 1, 2

),

loyalty as (

    select
        customer_id,
        location_id,
        first_order_date,
        last_order_date,
        order_count,
        pretax_spend,
        tax_paid,
        total_spend,
        average_order_value

    from {{ ref('customer_location_loyalty') }}

)

select
    orders_by_customer_location.customer_id,
    orders_by_customer_location.location_id

from orders_by_customer_location

full outer join loyalty
    on orders_by_customer_location.customer_id = loyalty.customer_id
    and orders_by_customer_location.location_id = loyalty.location_id

where
    orders_by_customer_location.customer_id is null
    or loyalty.customer_id is null
    or orders_by_customer_location.first_order_date != loyalty.first_order_date
    or orders_by_customer_location.last_order_date != loyalty.last_order_date
    or orders_by_customer_location.order_count != loyalty.order_count
    -- Currency comparisons allow up to one cent for warehouse-specific numeric
    -- aggregation and division behavior.
    or abs(orders_by_customer_location.pretax_spend - loyalty.pretax_spend) > 0.01
    or abs(orders_by_customer_location.tax_paid - loyalty.tax_paid) > 0.01
    or abs(orders_by_customer_location.total_spend - loyalty.total_spend) > 0.01
    or abs(
        orders_by_customer_location.total_spend
        / orders_by_customer_location.order_count
        - loyalty.average_order_value
    ) > 0.01
