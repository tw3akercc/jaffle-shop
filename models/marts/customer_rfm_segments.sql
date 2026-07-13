with

customers as (

    select * from {{ ref('stg_customers') }}

),

orders as (

    select * from {{ ref('orders') }}

),

dataset_dates as (

    select cast(max(ordered_at) as date) as analysis_date

    from orders

),

customer_order_metrics as (

    select
        customers.customer_id,
        cast(min(orders.ordered_at) as date) as first_order_date,
        cast(max(orders.ordered_at) as date) as last_order_date,
        count(distinct orders.order_id) as frequency,
        coalesce(sum(orders.subtotal), 0) as pretax_monetary_value

    from customers

    left join orders
        on customers.customer_id = orders.customer_id

    group by 1

),

rfm_metrics as (

    select
        customer_order_metrics.customer_id,
        dataset_dates.analysis_date,
        customer_order_metrics.first_order_date,
        customer_order_metrics.last_order_date,
        case
            when customer_order_metrics.frequency > 0
                then {{ dbt.datediff(
                    'customer_order_metrics.last_order_date',
                    'dataset_dates.analysis_date',
                    'day'
                ) }}
        end as recency_days,
        customer_order_metrics.frequency,
        customer_order_metrics.pretax_monetary_value,
        case
            when customer_order_metrics.frequency = 0 then 0
            else customer_order_metrics.pretax_monetary_value
                / customer_order_metrics.frequency
        end as average_order_value,
        case
            when customer_order_metrics.frequency > 0
                then {{ dbt.datediff(
                    'customer_order_metrics.first_order_date',
                    'dataset_dates.analysis_date',
                    'day'
                ) }}
        end as tenure_days

    from customer_order_metrics

    cross join dataset_dates

),

rfm_scores as (

    select
        *,
        case
            when frequency = 0 then 0
            when recency_days <= 30 then 5
            when recency_days <= 60 then 4
            when recency_days <= 90 then 3
            when recency_days <= 180 then 2
            else 1
        end as recency_score,
        case
            when frequency >= 5 then 5
            when frequency = 4 then 4
            when frequency = 3 then 3
            when frequency = 2 then 2
            when frequency = 1 then 1
            else 0
        end as frequency_score,
        case
            when pretax_monetary_value >= 200 then 5
            when pretax_monetary_value >= 100 then 4
            when pretax_monetary_value >= 50 then 3
            when pretax_monetary_value >= 20 then 2
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
            when recency_score >= 4 and frequency_score >= 2 then 'potential_loyalist'
            when recency_score >= 4 and frequency_score = 1 then 'new_customer'
            when recency_score <= 2
                and (frequency_score >= 3 or monetary_score >= 3)
                then 'at_risk'
            else 'hibernating'
        end as customer_segment

    from rfm_scores

)

select * from segmented
