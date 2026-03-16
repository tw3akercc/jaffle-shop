{% docs monthly_revenue_report %}
Monthly revenue report by store location for finance team analysis.
Grain: one row per location_id per calendar month, only for months with orders.
{% enddocs %}

{% docs monthly_revenue_report__location_id %}
The unique identifier for the store location.
{% enddocs %}

{% docs monthly_revenue_report__location_name %}
The name of the store location.
{% enddocs %}

{% docs monthly_revenue_report__month %}
The calendar month (truncated to month start) for the revenue data.
{% enddocs %}

{% docs monthly_revenue_report__monthly_revenue %}
Total revenue for the location in the given month, calculated as sum of subtotal from orders.
{% enddocs %}

{% docs monthly_revenue_report__monthly_order_count %}
Count of distinct orders for the location in the given month.
{% enddocs %}

{% docs monthly_revenue_report__mom_revenue_growth_pct %}
Month-over-month revenue growth percentage, calculated as ((current_month - previous_month) / previous_month) * 100. Null for the first month of each location.
{% enddocs %}

{% docs monthly_revenue_report__cumulative_revenue %}
Running total of revenue for the location up to and including the current month.
{% enddocs %}

{% docs monthly_revenue_report__revenue_contribution_pct %}
The current month's revenue as a percentage of the location's cumulative revenue up to that point.
{% enddocs %}
