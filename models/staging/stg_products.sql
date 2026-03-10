-- depends_on: {{ ref('raw_products') }}

with source as (

    select
        sku,
        name,
        type,
        description,
        price
    from {{ source('ecom', 'raw_products') }}

),

renamed as (

    select
        nullif(upper(trim(sku)), '') as product_id,
        nullif(trim(name), '') as product_name,
        nullif(trim(type), '') as product_type,
        nullif(trim(description), '') as product_description,
        cast(price as decimal(18, 2)) / 100 as product_price,
        coalesce(lower(type) = 'jaffle', false) as is_food_item,
        coalesce(lower(type) = 'beverage', false) as is_drink_item
    from source

)

select
    product_id,
    product_name,
    product_type,
    product_description,
    product_price,
    is_food_item,
    is_drink_item
from renamed
