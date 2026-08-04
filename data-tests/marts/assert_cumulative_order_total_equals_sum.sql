-- For each location_id, the maximum cumulative_order_total must equal
-- the sum of monthly_order_total. Any row returned by this query is a failure.
select
    location_id,
    sum(monthly_order_total) as total_monthly,
    max(cumulative_order_total) as max_cumulative

from {{ ref('location_monthly_revenue') }}

group by location_id

having
    abs(
        sum(monthly_order_total) - max(cumulative_order_total)
    ) > 0.01
