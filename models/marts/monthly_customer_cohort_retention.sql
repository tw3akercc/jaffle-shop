with

orders as (

    select
        customer_id,
        cast({{ dbt.date_trunc('month', 'ordered_at') }} as date)
            as activity_month,
        subtotal as pretax_revenue

    from {{ ref('orders') }}

),

latest_order_month as (

    select max(activity_month) as latest_activity_month

    from orders

),

customer_cohorts as (

    select
        customer_id,
        min(activity_month) as cohort_month

    from orders

    group by 1

),

cohort_sizes as (

    select
        cohort_month,
        count(*) as cohort_size

    from customer_cohorts

    group by 1

),

month_offsets as (

    -- Jaffle Shop generates at most ten years of history. This larger portable
    -- series leaves ample room without relying on warehouse-specific
    -- generators.
    {{ dbt_utils.generate_series(upper_bound=1200) }}

),

cohort_activity_months as (

    select
        cohort_sizes.cohort_month,
        cast(
            {{ dbt.dateadd(
                'month',
                'month_offsets.generated_number - 1',
                'cohort_sizes.cohort_month'
            ) }}
            as date
        ) as activity_month,
        month_offsets.generated_number - 1 as months_since_acquisition,
        cohort_sizes.cohort_size

    from cohort_sizes

    cross join month_offsets

    cross join latest_order_month

    where {{ dbt.dateadd(
        'month',
        'month_offsets.generated_number - 1',
        'cohort_sizes.cohort_month'
    ) }} <= latest_order_month.latest_activity_month

),

monthly_activity as (

    select
        customer_cohorts.cohort_month,
        orders.activity_month,
        count(distinct orders.customer_id) as active_customers,
        count(*) as order_count,
        sum(orders.pretax_revenue) as pretax_revenue

    from orders

    inner join customer_cohorts
        on orders.customer_id = customer_cohorts.customer_id

    group by 1, 2

),

zero_filled as (

    select
        cohort_activity_months.cohort_month,
        cohort_activity_months.activity_month,
        cohort_activity_months.months_since_acquisition,
        cohort_activity_months.cohort_size,
        coalesce(monthly_activity.active_customers, 0) as active_customers,
        coalesce(monthly_activity.order_count, 0) as order_count,
        coalesce(monthly_activity.pretax_revenue, 0) as pretax_revenue

    from cohort_activity_months

    left join monthly_activity
        on cohort_activity_months.cohort_month = monthly_activity.cohort_month
        and cohort_activity_months.activity_month
        = monthly_activity.activity_month

)

select
    cohort_month,
    activity_month,
    months_since_acquisition,
    cohort_size,
    active_customers,
    1.0 * {{ dbt_utils.safe_divide('active_customers', 'cohort_size') }}
        as retention_rate,
    order_count,
    pretax_revenue,
    1.0 * {{ dbt_utils.safe_divide('pretax_revenue', 'cohort_size') }}
        as revenue_per_original_cohort_customer,
    1.0 * {{ dbt_utils.safe_divide('pretax_revenue', 'active_customers') }}
        as revenue_per_active_customer

from zero_filled
