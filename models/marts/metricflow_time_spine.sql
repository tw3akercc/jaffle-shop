with days as (

    select
        cast(date_day as date) as date_day
    from generate_series(
        date '2000-01-01',
        date '2030-12-31',
        interval 1 day
    ) as t(date_day)

)

select
    date_day
from days
