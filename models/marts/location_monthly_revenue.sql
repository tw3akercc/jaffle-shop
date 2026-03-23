with

orders as (

    select
        order_id,
        location_id,
        subtotal,
        order_total,
        {{ dbt.date_trunc('month', 'ordered_at') }} as revenue_month

    from {{ ref('stg_orders') }}

),

locations as (

    select
        location_id,
        location_name

    from {{ ref('locations') }}

),

monthly_agg as (

    select
        location_id,
        revenue_month,
        sum(order_total) as monthly_revenue,
        sum(subtotal) as monthly_revenue_pretax,
        count(order_id) as monthly_order_count

    from orders

    group by 1, 2

),

joined as (

    select
        monthly_agg.location_id,
        locations.location_name,
        monthly_agg.revenue_month,
        monthly_agg.monthly_order_count,
        monthly_agg.monthly_revenue,
        monthly_agg.monthly_revenue_pretax

    from monthly_agg

    left join locations
        on monthly_agg.location_id = locations.location_id

),

final as (

    select
        location_id,
        location_name,
        revenue_month,
        monthly_order_count,
        monthly_revenue,
        monthly_revenue_pretax,
        (monthly_revenue - lag(monthly_revenue) over (
            partition by location_id
            order by revenue_month
        )) / lag(monthly_revenue) over (
            partition by location_id
            order by revenue_month
        ) * 100 as mom_revenue_growth_pct,
        sum(monthly_revenue) over (
            partition by location_id
            order by revenue_month
            rows between unbounded preceding and current row
        ) as cumulative_revenue,
        monthly_revenue / sum(monthly_revenue) over (
            partition by location_id
        ) * 100 as pct_of_location_total_revenue

    from joined

)

select * from final