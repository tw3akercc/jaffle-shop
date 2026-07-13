select
    calendar_month,
    sum(share_of_monthly_supply_spend) as total_share

from {{ ref('monthly_supply_requirements') }}

group by 1

having abs(sum(share_of_monthly_supply_spend) - 1) > 0.000001
