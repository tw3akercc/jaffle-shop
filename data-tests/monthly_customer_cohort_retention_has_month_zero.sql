select cohort_month

from {{ ref('monthly_customer_cohort_retention') }}

group by 1

having min(months_since_acquisition) <> 0
    or sum(case when months_since_acquisition = 0 then 1 else 0 end) <> 1
