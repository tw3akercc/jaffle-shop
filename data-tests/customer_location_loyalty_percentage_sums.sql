-- Each customer's location percentages must sum to 100. The 0.000001
-- tolerance accounts for floating-point division and summation.
select
    customer_id,
    sum(percentage_of_customer_orders) as order_percentage_sum,
    sum(percentage_of_customer_spend) as spend_percentage_sum

from {{ ref('customer_location_loyalty') }}

group by 1

having
    abs(sum(percentage_of_customer_orders) - 100.0) > 0.000001
    or abs(sum(percentage_of_customer_spend) - 100.0) > 0.000001
