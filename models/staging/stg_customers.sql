-- depends_on: {{ ref('raw_customers') }}

with source as (

    select
        id,
        name
    from {{ source('ecom', 'raw_customers') }}

),

renamed as (

    select
        nullif(trim(id), '') as customer_id,
        nullif(trim(name), '') as customer_name
    from source

)

select
    customer_id,
    customer_name
from renamed
