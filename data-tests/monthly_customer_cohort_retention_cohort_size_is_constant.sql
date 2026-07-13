select cohort_month

from {{ ref('monthly_customer_cohort_retention') }}

group by 1

having min(cohort_size) <> max(cohort_size)
