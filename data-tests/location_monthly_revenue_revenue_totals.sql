-- Assert sum of monthly_revenue in location_monthly_revenue equals
-- sum of subtotal in stg_orders grouped by location_id

with

model_aggregation as (

    select
        location_id,
        sum(monthly_revenue) as total_revenue
    from {{ ref('location_monthly_revenue') }}
    group by location_id

),

source_aggregation as (

    select
        location_id,
        sum(subtotal) as total_revenue
    from {{ ref('stg_orders') }}
    group by location_id

),

comparison as (

    select
        model_aggregation.location_id,
        model_aggregation.total_revenue as model_total,
        source_aggregation.total_revenue as source_total
    from model_aggregation
    full outer join source_aggregation
        on model_aggregation.location_id = source_aggregation.location_id

),

invalid_rows as (

    select *
    from comparison
    where
        -- Handle cases where a location has no orders but appears in the model
        -- (model_total would be 0, source_total would be null)
        abs(coalesce(model_total, 0) - coalesce(source_total, 0)) > 0.01

)

select * from invalid_rows
