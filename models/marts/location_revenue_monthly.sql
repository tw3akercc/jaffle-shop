{{ config(materialized='table') }}

with

orders as (

    select * from {{ ref('orders') }}

),

locations as (

    select * from {{ ref('locations') }}

),

time_spine as (

    select * from {{ ref('metricflow_time_spine') }}

),

-- aggregate orders to monthly grain per location
monthly_order_agg as (

    select
        location_id
        , {{ dbt.date_trunc('month', 'ordered_at') }} as revenue_month
        , sum(subtotal) as monthly_revenue
        , count(order_id) as monthly_order_count

    from orders

    group by
        location_id
        , {{ dbt.date_trunc('month', 'ordered_at') }}

),

-- derive global date range from orders
global_date_range as (

    select
        min({{ dbt.date_trunc('month', 'ordered_at') }}) as min_month
        , max({{ dbt.date_trunc('month', 'ordered_at') }}) as max_month

    from orders

),

-- generate one row per distinct calendar month within the global range
month_spine as (

    select distinct
        {{ dbt.date_trunc('month', 'date_day') }} as revenue_month

    from time_spine

    cross join global_date_range

    where {{ dbt.date_trunc('month', 'date_day') }} >= global_date_range.min_month
        and {{ dbt.date_trunc('month', 'date_day') }} <= global_date_range.max_month

),

-- distinct locations that have at least one order
location_spine as (

    select distinct
        location_id

    from orders

),

-- cross join to produce every location-month combination
spine as (

    select
        location_spine.location_id
        , month_spine.revenue_month

    from location_spine

    cross join month_spine

),

-- left join actuals onto spine, zero-filling gaps
zero_filled as (

    select
        spine.location_id
        , spine.revenue_month
        , coalesce(monthly_order_agg.monthly_revenue, 0) as monthly_revenue
        , coalesce(monthly_order_agg.monthly_order_count, 0) as monthly_order_count

    from spine

    left join monthly_order_agg
        on spine.location_id = monthly_order_agg.location_id
        and spine.revenue_month = monthly_order_agg.revenue_month

),

-- join location display names
with_location_names as (

    select
        zero_filled.location_id
        , locations.location_name
        , zero_filled.revenue_month
        , zero_filled.monthly_revenue
        , zero_filled.monthly_order_count

    from zero_filled

    left join locations
        on zero_filled.location_id = locations.location_id

),

-- apply window function metrics
final as (

    select
        location_id
        , location_name
        , revenue_month
        , monthly_revenue
        , monthly_order_count
        , (
            monthly_revenue
            - lag(monthly_revenue) over (
                partition by location_id
                order by revenue_month
            )
        ) / nullif(
            lag(monthly_revenue) over (
                partition by location_id
                order by revenue_month
            )
            , 0
        ) * 100 as revenue_mom_growth_pct
        , sum(monthly_revenue) over (
            partition by location_id
            order by revenue_month
        ) as cumulative_revenue
        , monthly_revenue / nullif(
            sum(monthly_revenue) over (partition by location_id)
            , 0
        ) * 100 as pct_of_all_time_revenue

    from with_location_names

)

select * from final
