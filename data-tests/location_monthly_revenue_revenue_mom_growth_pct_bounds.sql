-- This test verifies that revenue_mom_growth_pct is either null (for the first month per location)
-- or >= -1 (growth cannot be below -100% since revenue cannot go below zero).

select *
from {{ ref('location_monthly_revenue') }}
where revenue_mom_growth_pct is not null
  and revenue_mom_growth_pct < -1
