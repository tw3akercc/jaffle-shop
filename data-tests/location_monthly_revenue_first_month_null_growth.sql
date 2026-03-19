-- Assert that for every location_id, the row with the earliest month
-- has a null mom_revenue_growth_pct

with

first_months as (

    select
        location_id,
        min(month) as earliest_month
    from {{ ref('location_monthly_revenue') }}
    group by location_id

),

first_month_growth as (

    select
        location_monthly_revenue.location_id,
        location_monthly_revenue.month,
        location_monthly_revenue.mom_revenue_growth_pct
    from {{ ref('location_monthly_revenue') }}
    inner join first_months
        on location_monthly_revenue.location_id = first_months.location_id
        and location_monthly_revenue.month = first_months.earliest_month

),

invalid_rows as (

    select *
    from first_month_growth
    where mom_revenue_growth_pct is not null

)

select * from invalid_rows
