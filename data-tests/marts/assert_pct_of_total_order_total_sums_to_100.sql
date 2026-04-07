-- For each location_id, the sum of pct_of_total_order_total must equal 100.
-- Each row is rounded to 2dp, so accumulation can drift up to n_months * 0.005.
-- We allow up to 0.5 total drift to handle any realistic number of months.
-- Any row returned by this query is a failure.
select
    location_id,
    count(*) as n_months,
    sum(pct_of_total_order_total) as total_pct

from {{ ref('location_monthly_revenue') }}

group by location_id

having
    abs(sum(pct_of_total_order_total) - 100) >= 0.5
