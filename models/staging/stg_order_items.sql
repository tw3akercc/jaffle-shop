{{ config(materialized='view') }}

with

source as (

    select * from {{ source('ecom', 'raw_items') }}

),

renamed as (

    select

        ----------  ids
        id as order_item_id,
        order_id,
        sku as product_id

    from source

),

final as (

    select * from renamed

)

select * from final
