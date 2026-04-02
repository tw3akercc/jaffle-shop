{% docs location_monthly_revenue %}
Monthly revenue aggregation per store location for finance close cycle reporting. Grain: one row per (location_id, month); months with zero orders for a location are excluded.
{% enddocs %}

{% docs location_monthly_revenue__location_id %}
The unique identifier for the store location. Primary key component; foreign key to locations.location_id.
{% enddocs %}

{% docs location_monthly_revenue__location_name %}
The human-readable store name sourced from locations.location_name.
{% enddocs %}

{% docs location_monthly_revenue__month %}
First day of the calendar month, derived by truncating ordered_at to month. Grain key alongside location_id.
{% enddocs %}

{% docs location_monthly_revenue__monthly_revenue %}
Sum of order_total for all orders placed at this location during the calendar month, including tax, in dollars.
{% enddocs %}

{% docs location_monthly_revenue__monthly_order_count %}
Count of orders placed at this location during the calendar month.
{% enddocs %}

{% docs location_monthly_revenue__mom_revenue_growth_pct %}
Month-over-month revenue growth as a percentage, rounded to 2 decimal places. Null for the first recorded month per location (no prior month to compare) and null if the prior month revenue was zero.
{% enddocs %}

{% docs location_monthly_revenue__cumulative_revenue %}
Running sum of monthly_revenue for this location from the earliest recorded month through the current month, inclusive.
{% enddocs %}

{% docs location_monthly_revenue__pct_of_location_total_revenue %}
The current month's revenue expressed as a percentage of the location's all-time total revenue across all months, rounded to 2 decimal places.
{% enddocs %}
