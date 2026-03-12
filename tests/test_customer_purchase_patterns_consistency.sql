{{
    config(
        enabled=true
    )
}}

select
    customer_id,
    order_id,
    order_number,
    previous_order_date,
    customer_status

from {{ ref('customer_purchase_patterns') }}

where order_number = 1
    and (
        previous_order_date is not null
        or customer_status != 'new'
    )