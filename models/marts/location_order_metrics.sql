with orders as (

    select
        so.order_id,
        so.location_id,
        so.order_total,
        so.ordered_at
    from stg_orders as so

),

order_supply_cost as (

    select
        oi.order_id,
        sum(oi.supply_cost) as order_supply_cost
    from order_items as oi
    group by 1

),

enriched_orders as (

    select
        o.order_id,
        o.location_id,
        o.order_total,
        o.ordered_at,
        coalesce(osc.order_supply_cost, 0) as order_supply_cost
    from orders as o
    left join order_supply_cost as osc
        on o.order_id = osc.order_id

)

select
    eo.location_id,
    sum(eo.order_total) as total_revenue,
    sum(eo.order_supply_cost) as total_supply_cost,
    count(eo.order_id) as order_count,
    min(eo.ordered_at) as first_order_date,
    max(eo.ordered_at) as last_order_date
from enriched_orders as eo
group by 1
