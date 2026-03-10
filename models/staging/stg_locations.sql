-- depends_on: {{ ref('raw_stores') }}
-- noqa: disable=ST06

with raw_stores as (

    select
        id,
        name,
        tax_rate,
        opened_at
    from {{ source('ecom', 'raw_stores') }}

),

renamed as (

    select
        tax_rate,
        nullif(trim(id), '') as location_id,
        nullif(trim(name), '') as location_name,
        cast(date_trunc('day', opened_at) as date) as opened_date
    from raw_stores

)

select
    location_id,
    location_name,
    tax_rate,
    opened_date
from renamed

-- noqa: enable=ST06
