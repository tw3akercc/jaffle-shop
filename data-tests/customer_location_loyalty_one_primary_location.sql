select
    customer_id,
    sum(case when is_primary_location then 1 else 0 end) as primary_location_count

from {{ ref('customer_location_loyalty') }}

group by 1

having sum(case when is_primary_location then 1 else 0 end) != 1
