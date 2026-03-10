-- depends_on: {{ ref('raw_orders') }}
-- noqa: disable=ST06

with raw_orders as (

    select
        id,
        store_id,
        customer,
        subtotal,
        tax_paid,
        order_total,
        ordered_at
    from {{ source('ecom', 'raw_orders') }}

),

renamed as (

    select
        nullif(trim(id), '') as order_id,
        nullif(trim(store_id), '') as location_id,
        nullif(trim(customer), '') as customer_id,
        cast(nullif(trim(cast(subtotal as varchar)), '') as bigint)
            as subtotal_cents,
        cast(nullif(trim(cast(tax_paid as varchar)), '') as bigint)
            as tax_paid_cents,
        cast(nullif(trim(cast(order_total as varchar)), '') as bigint)
            as order_total_cents,
        cast(date_trunc('day', ordered_at) as date) as ordered_at
    from raw_orders

),

final as (

    select
        order_id,
        location_id,
        customer_id,
        subtotal_cents,
        tax_paid_cents,
        order_total_cents,
        subtotal_cents / 100.00 as subtotal,
        tax_paid_cents / 100.00 as tax_paid,
        (subtotal_cents + tax_paid_cents) / 100.00 as order_total,
        ordered_at
    from renamed

)

select
    order_id,
    location_id,
    customer_id,
    subtotal_cents,
    tax_paid_cents,
    order_total_cents,
    subtotal,
    tax_paid,
    order_total,
    ordered_at
from final

-- noqa: enable=ST06
