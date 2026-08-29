with

customers as (

    select
        customer_id,
        first_ordered_at,
        last_ordered_at,
        count_lifetime_orders,
        lifetime_spend_pretax

    from {{ ref('customers') }}

),

dataset_dates as (

    select
        cast(max(last_ordered_at) as date) as analysis_date

    from customers

),

customer_base as (

    select
        customer_id,
        cast(first_ordered_at as date) as first_order_date,
        cast(last_ordered_at as date) as last_order_date,
        coalesce(count_lifetime_orders, 0) as frequency,
        coalesce(lifetime_spend_pretax, 0) as pretax_monetary_value

    from customers

),

rfm_metrics as (

    select
        customer_base.customer_id,
        dataset_dates.analysis_date,
        customer_base.first_order_date,
        customer_base.last_order_date,
        case
            when customer_base.frequency > 0
                then {{ dbt.datediff(
                    'customer_base.last_order_date',
                    'dataset_dates.analysis_date',
                    'day'
                ) }}
        end as recency_days,
        customer_base.frequency,
        customer_base.pretax_monetary_value,
        case
            when customer_base.frequency = 0 then 0
            else customer_base.pretax_monetary_value
                / customer_base.frequency
        end as average_order_value,
        case
            when customer_base.frequency > 0
                then {{ dbt.datediff(
                    'customer_base.first_order_date',
                    'dataset_dates.analysis_date',
                    'day'
                ) }}
        end as tenure_days

    from customer_base

    cross join dataset_dates

),

rfm_scores as (

    select
        *,
        case
            when frequency = 0 then 0
            when recency_days <= 7 then 5
            when recency_days <= 14 then 4
            when recency_days <= 30 then 3
            when recency_days <= 90 then 2
            else 1
        end as recency_score,
        case
            when frequency >= 100 then 5
            when frequency >= 50 then 4
            when frequency >= 25 then 3
            when frequency >= 10 then 2
            when frequency >= 1 then 1
            else 0
        end as frequency_score,
        case
            when pretax_monetary_value >= 1000 then 5
            when pretax_monetary_value >= 500 then 4
            when pretax_monetary_value >= 250 then 3
            when pretax_monetary_value >= 100 then 2
            when pretax_monetary_value > 0 then 1
            else 0
        end as monetary_score

    from rfm_metrics

),

segmented as (

    select
        *,
        concat(
            cast(recency_score as {{ dbt.type_string() }}),
            cast(frequency_score as {{ dbt.type_string() }}),
            cast(monetary_score as {{ dbt.type_string() }})
        ) as rfm_code,
        case
            when frequency = 0 then 'no_purchase'
            when recency_score >= 4
                and frequency_score >= 4
                and monetary_score >= 4
                then 'champion'
            when recency_score >= 3 and frequency_score >= 3 then 'loyal'
            when recency_score >= 4
                and frequency_score >= 2
                then 'potential_loyalist'
            when recency_score >= 4 and frequency_score = 1
                then 'new_customer'
            when recency_score <= 2
                and (
                    frequency_score >= 3
                    or monetary_score >= 3
                )
                then 'at_risk'
            else 'hibernating'
        end as customer_segment

    from rfm_scores

)

select * from segmented
