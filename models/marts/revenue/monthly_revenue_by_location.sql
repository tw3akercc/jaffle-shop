{{ config(materialized='table') }}

with

orders as (

    select * from {{ ref('orders') }}

),

locations as (

    select * from {{ ref('locations') }}

),

monthly_by_location as (

    select
        orders.location_id,
        locations.location_name,
        {{ dbt.date_trunc('month', 'ordered_at') }} as month_start,
        extract(year from ordered_at) as year,
        extract(month from ordered_at) as month,
        sum(orders.order_total) as monthly_revenue,
        count(distinct orders.order_id) as order_count

    from orders

    inner join
        locations
        on orders.location_id = locations.location_id

    group by
        orders.location_id,
        locations.location_name,
        month_start,
        year,
        month

),

with_mom_growth as (

    select
        *,
        case
            when lag(monthly_revenue) over (
                partition by location_id
                order by year, month
            ) = 0 then null
            else (
                monthly_revenue - lag(monthly_revenue) over (
                    partition by location_id
                    order by year, month
                )
            ) / nullif(
                lag(monthly_revenue) over (
                    partition by location_id
                    order by year, month
                ),
                0
            ) * 100
        end as mom_revenue_growth_pct

    from monthly_by_location

),

with_cumulative_revenue as (

    select
        *,
        sum(monthly_revenue) over (
            partition by location_id
            order by year, month
            rows between unbounded preceding and current row
        ) as cumulative_revenue

    from with_mom_growth

),

with_revenue_pct as (

    select
        *,
        monthly_revenue / sum(monthly_revenue) over (
            partition by location_id
        ) * 100 as revenue_pct_of_location_total

    from with_cumulative_revenue

)

select * from with_revenue_pct

order by
    location_name,
    year,
    month
