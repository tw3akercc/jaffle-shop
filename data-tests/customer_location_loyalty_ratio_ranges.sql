-- Percentages use a 0-to-100 scale. The 0.000001 tolerance allows for
-- floating-point differences introduced by division across database adapters.
select *

from {{ ref('customer_location_loyalty') }}

where
    percentage_of_customer_orders < -0.000001
    or percentage_of_customer_orders > 100.000001
    or percentage_of_customer_spend < -0.000001
    or percentage_of_customer_spend > 100.000001
