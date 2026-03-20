with

-- Step 1: Build month spine from metricflow_time_spine
month_spine as (

    select distinct
        date_trunc('month', date_day) as month

    from {{ ref('metricflow_time_spine') }}

    where date_day between (
        select min(ordered_at)
        from {{ ref('orders') }}
    ) and current_date

),

-- Step 2: Cross-join spine with locations to create zero-fill scaffold
location_month_scaffold as (

    select
        month_spine.month,
        locations.location_id,
        locations.location_name

    from month_spine

    cross join {{ ref('locations') }}

),

-- Step 3: Aggregate orders to month × location grain
order_aggregates as (

    select
        date_trunc('month', ordered_at) as month,
        location_id,
        sum(order_total) as monthly_revenue,
        count(order_id) as monthly_order_count

    from {{ ref('orders') }}

    group by 1, 2

),

-- Step 4: Left-join actuals onto scaffold with coalesce for zero-fill
scaffold_with_actuals as (

    select
        location_month_scaffold.month,
        location_month_scaffold.location_id,
        location_month_scaffold.location_name,
        coalesce(order_aggregates.monthly_revenue, 0) as monthly_revenue,
        coalesce(order_aggregates.monthly_order_count, 0) as monthly_order_count

    from location_month_scaffold

    left join order_aggregates
        on location_month_scaffold.month = order_aggregates.month
        and location_month_scaffold.location_id = order_aggregates.location_id

),

-- Step 5: Compute window functions
final as (

    select
        month,
        location_id,
        location_name,
        monthly_revenue,
        monthly_order_count,

        -- Month-over-month revenue growth %
        (
            monthly_revenue
            - lag(monthly_revenue) over (
                partition by location_id
                order by month
            )
        )
        / nullif(
            lag(monthly_revenue) over (
                partition by location_id
                order by month
            ),
            0
        ) as revenue_mom_growth_pct,

        -- Cumulative revenue (running sum)
        sum(monthly_revenue) over (
            partition by location_id
            order by month
            rows between unbounded preceding and current row
        ) as cumulative_revenue,

        -- % of location's all-time revenue
        monthly_revenue
        / nullif(
            sum(monthly_revenue) over (partition by location_id),
            0
        ) as pct_of_location_total_revenue

    from scaffold_with_actuals

)

select * from final
