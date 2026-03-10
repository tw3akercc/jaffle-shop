-- depends_on: {{ ref('raw_items') }}

with raw_items as (

    select
        id,
        order_id,
        sku
    from {{ source('ecom', 'raw_items') }}

),

renamed as (

    select
        nullif(trim(id), '') as order_item_id,
        nullif(trim(order_id), '') as order_id,
        nullif(upper(trim(sku)), '') as product_id
    from raw_items

)

select
    order_item_id,
    order_id,
    product_id
from renamed
