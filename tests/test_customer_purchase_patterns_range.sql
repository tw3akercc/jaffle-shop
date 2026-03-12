{{
    config(
        enabled=true
    )
}}

select
    customer_id,
    order_id,
    days_since_previous_order

from {{ ref('customer_purchase_patterns') }}

where days_since_previous_order is not null
    and days_since_previous_order < 0