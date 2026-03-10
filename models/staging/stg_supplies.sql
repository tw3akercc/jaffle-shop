-- depends_on: {{ ref('raw_supplies') }}

with source as (

    select
        id,
        sku,
        name,
        cost,
        perishable
    from {{ source('ecom', 'raw_supplies') }}

),

renamed as (

    select
        md5(
            coalesce(trim(id), '') || '-' || coalesce(trim(sku), '')
        ) as supply_uuid,
        nullif(trim(id), '') as supply_id,
        nullif(upper(trim(sku)), '') as product_id,
        nullif(trim(name), '') as supply_name,
        cast(cost as decimal(18, 2)) / 100 as supply_cost,
        coalesce(perishable, false) as is_perishable_supply
    from source

)

select
    supply_uuid,
    supply_id,
    product_id,
    supply_name,
    supply_cost,
    is_perishable_supply
from renamed
