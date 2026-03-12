{% docs location_performance %}
Location performance mart providing comprehensive business metrics for each store location. 
Grain: One row per unique store location.
Includes revenue, costs, profitability, order metrics, customer metrics, and revenue breakdown by category.
{% enddocs %}

{% docs location_performance__location_id %}
The unique identifier for the store location. Primary key of this model.
{% enddocs %}

{% docs location_performance__location_name %}
The name of the store location.
{% enddocs %}

{% docs location_performance__tax_rate %}
The tax rate applicable to the store location.
{% enddocs %}

{% docs location_performance__opened_date %}
The date when the store location opened.
{% enddocs %}

{% docs location_performance__total_revenue %}
Total pre-tax revenue for the location (sum of order subtotals).
{% enddocs %}

{% docs location_performance__total_supply_cost %}
Total supply cost for the location (sum of supply costs from order items).
{% enddocs %}

{% docs location_performance__gross_profit %}
Gross profit calculated as total_revenue minus total_supply_cost.
{% enddocs %}

{% docs location_performance__gross_margin_pct %}
Gross margin percentage calculated as (gross_profit / total_revenue) * 100.
{% enddocs %}

{% docs location_performance__total_tax_collected %}
Total tax collected for the location (sum of tax_paid from orders).
{% enddocs %}

{% docs location_performance__order_count %}
Total number of orders placed at the location.
{% enddocs %}

{% docs location_performance__avg_order_value %}
Average order value calculated as total_revenue divided by order_count.
{% enddocs %}

{% docs location_performance__unique_customer_count %}
Count of distinct customers who have placed orders at the location.
{% enddocs %}

{% docs location_performance__repeat_customer_count %}
Count of distinct customers who have placed more than one order at the location.
{% enddocs %}

{% docs location_performance__food_revenue %}
Total revenue from food items for the location.
{% enddocs %}

{% docs location_performance__drink_revenue %}
Total revenue from drink items for the location.
{% enddocs %}

{% docs location_performance__food_revenue_pct %}
Percentage of total revenue from food items, calculated as (food_revenue / total_revenue) * 100.
{% enddocs %}

{% docs location_performance__drink_revenue_pct %}
Percentage of total revenue from drink items, calculated as (drink_revenue / total_revenue) * 100.
{% enddocs %}

{% docs location_performance__first_order_date %}
The date of the first order placed at the location.
{% enddocs %}

{% docs location_performance__last_order_date %}
The date of the most recent order placed at the location.
{% enddocs %}
