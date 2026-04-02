{{ config(materialized='table') }}

with

orders as (

    select * from {{ ref('orders') }}

),

locations as (

    select * from {{ ref('locations') }}

),

joined as (

    select
        orders.order_id,
        orders.location_id,
        orders.order_total,
        {{ dbt.date_trunc('month', 'orders.ordered_at') }} as month,
        locations.location_name

    from orders

    inner join
        locations
        on orders.location_id = locations.location_id

),

monthly_aggregated as (

    select
        location_id,
        location_name,
        month,
        sum(order_total) as monthly_revenue,
        count(order_id) as monthly_order_count

    from joined

    group by
        location_id,
        location_name,
        month

),

window_calculations as (

    select
        location_id,
        location_name,
        month,
        monthly_revenue,
        monthly_order_count,
        lag(monthly_revenue) over (
            partition by location_id
            order by month asc
        ) as prior_month_revenue,
        sum(monthly_revenue) over (
            partition by location_id
            order by month asc
            rows between unbounded preceding and current row
        ) as cumulative_revenue,
        sum(monthly_revenue) over (
            partition by location_id
        ) as location_total_revenue

    from monthly_aggregated

),

final as (

    select
        location_id,
        location_name,
        month,
        monthly_revenue,
        monthly_order_count,
        case
            when prior_month_revenue is null or prior_month_revenue = 0 then null
            else round(
                (monthly_revenue - prior_month_revenue) / prior_month_revenue * 100,
                2
            )
        end as mom_revenue_growth_pct,
        cumulative_revenue,
        round(
            monthly_revenue / location_total_revenue * 100,
            2
        ) as pct_of_location_total_revenue

    from window_calculations

)

select * from final
