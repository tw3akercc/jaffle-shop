{% docs location_revenue_monthly %}
Monthly revenue aggregation per location for finance reporting. Grain: one row per location per calendar month, including zero-fill months with no orders. Covers all calendar months between the global min and max order dates.
{% enddocs %}

{% docs location_revenue_monthly__location_id %}
The unique identifier for the store location, from the orders mart.
{% enddocs %}

{% docs location_revenue_monthly__location_name %}
The display name of the store location, joined from the locations mart.
{% enddocs %}

{% docs location_revenue_monthly__revenue_month %}
The calendar month of the aggregation period, truncated to the first day of the month using date_trunc('month', ordered_at).
{% enddocs %}

{% docs location_revenue_monthly__monthly_revenue %}
Total pre-tax order revenue (sum of subtotal) for the location in the given month. Zero-filled to 0 for months with no orders.
{% enddocs %}

{% docs location_revenue_monthly__monthly_order_count %}
Total number of orders placed at the location in the given month. Zero-filled to 0 for months with no orders.
{% enddocs %}

{% docs location_revenue_monthly__revenue_mom_growth_pct %}
Month-over-month revenue growth percentage for the location. NULL for the first month of each location and when the prior month revenue is $0.
{% enddocs %}

{% docs location_revenue_monthly__cumulative_revenue %}
Running total of pre-tax revenue for the location from the earliest month through the current month. Resets per location.
{% enddocs %}

{% docs location_revenue_monthly__pct_of_all_time_revenue %}
Each month's revenue as a percentage of the location's all-time total revenue. Sums to 100 per location (within floating-point tolerance).
{% enddocs %}
