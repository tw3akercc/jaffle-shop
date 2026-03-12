{{ config(materialized='table') }}

with

customers as (

    select
        customer_id,
        customer_name

    from {{ ref('customers') }}

),

orders as (

    select
        order_id,
        customer_id,
        ordered_at as order_date,
        order_total as order_amount

    from {{ ref('orders') }}

),

joined as (

    select
        orders.order_id,
        orders.customer_id,
        customers.customer_name,
        orders.order_date,
        orders.order_amount,

        row_number() over (
            partition by orders.customer_id
            order by orders.order_date asc
        ) as order_number,

        lag(orders.order_date, 1) over (
            partition by orders.customer_id
            order by orders.order_date asc
        ) as previous_order_date,

        datediff(
            'day',
            lag(orders.order_date, 1) over (
                partition by orders.customer_id
                order by orders.order_date asc
            ),
            orders.order_date
        ) as days_since_previous_order

    from orders

    inner join customers
        on orders.customer_id = customers.customer_id

),

with_avg as (

    select
        joined.*,

        avg(joined.days_since_previous_order) over (
            partition by joined.customer_id
        ) as avg_days_between_orders

    from joined

),

final as (

    select
        customer_id,
        customer_name,
        order_id,
        order_date,
        order_amount,
        order_number,
        previous_order_date,
        days_since_previous_order,
        avg_days_between_orders,

        case
            when order_number = 1 then 'new'
            when days_since_previous_order <= 30 then 'active'
            when days_since_previous_order <= 60 then 'at_risk'
            else 'lapsed'
        end as customer_status

    from with_avg

)

select * from final