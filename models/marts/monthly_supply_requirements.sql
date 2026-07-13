with

monthly_product_sales as (

    select
        {{ dbt.date_trunc('month', 'orders.ordered_at') }} as calendar_month,
        order_items.product_id,
        count(*) as menu_items_sold

    from {{ ref('stg_order_items') }} as order_items

    inner join {{ ref('stg_orders') }} as orders
        on order_items.order_id = orders.order_id

    group by 1, 2

),

recipe_requirements as (

    select
        {{ dbt_utils.generate_surrogate_key([
            'monthly_product_sales.calendar_month',
            'monthly_product_sales.product_id',
            'supplies.supply_uuid'
        ]) }} as monthly_supply_requirement_uuid,
        monthly_product_sales.calendar_month,

        products.product_id,
        products.product_name,
        products.product_type,
        products.product_description,

        supplies.supply_uuid,
        supplies.supply_id,
        supplies.supply_name,
        supplies.is_perishable_supply,
        supplies.supply_cost as supply_unit_cost,

        monthly_product_sales.menu_items_sold,
        monthly_product_sales.menu_items_sold
            as estimated_supply_units_required,
        monthly_product_sales.menu_items_sold * supplies.supply_cost
            as estimated_supply_spend

    from monthly_product_sales

    inner join {{ ref('stg_products') }} as products
        on monthly_product_sales.product_id = products.product_id

    inner join {{ ref('stg_supplies') }} as supplies
        on monthly_product_sales.product_id = supplies.product_id

),

final as (

    select
        *,
        estimated_supply_spend
        / nullif(
            sum(estimated_supply_spend) over (partition by calendar_month),
            0
        ) as share_of_monthly_supply_spend,
        case
            when is_perishable_supply then estimated_supply_spend
            else 0
        end as estimated_perishable_supply_spend

    from recipe_requirements

)

select * from final
