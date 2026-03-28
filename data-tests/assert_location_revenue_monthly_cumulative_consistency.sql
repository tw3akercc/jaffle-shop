-- Validates that for each location, max(cumulative_revenue) equals
-- sum(monthly_revenue) across all months. Returns rows for any location
-- where cumulative revenue is inconsistent with monthly totals.

select
    location_id,
    max(cumulative_revenue) as max_cumulative_revenue,
    sum(monthly_revenue) as total_monthly_revenue

from {{ ref('location_revenue_monthly') }}

group by location_id

having abs(max(cumulative_revenue) - sum(monthly_revenue)) > 0.01
