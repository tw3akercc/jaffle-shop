-- Assert no location has a month before its opened_date

with

invalid_rows as (

    select
        location_monthly_revenue.location_id,
        location_monthly_revenue.month,
        locations.opened_date
    from {{ ref('location_monthly_revenue') }}
    inner join {{ ref('locations') }}
        on location_monthly_revenue.location_id = locations.location_id
    where
        location_monthly_revenue.month
        < {{ dbt.date_trunc('month', 'locations.opened_date') }}

)

select * from invalid_rows
