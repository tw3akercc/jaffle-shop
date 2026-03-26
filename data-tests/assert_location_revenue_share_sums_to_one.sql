-- Validates that pct_of_location_revenue sums to 1.0 per location_id
-- within floating-point tolerance (0.0001).
-- Returns rows for any location where the sum deviates from 1.0.

select
    location_id,
    sum(pct_of_location_revenue) as total_pct,
    abs(sum(pct_of_location_revenue) - 1) as deviation

from {{ ref('location_monthly_revenue') }}

group by location_id

having abs(sum(pct_of_location_revenue) - 1) > 0.0001
