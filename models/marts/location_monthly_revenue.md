{% docs location_monthly_revenue %}
Monthly revenue breakdown by store location for finance team analysis.

Grain: one row per location per calendar month. Every location appears for every month
in the data range, including months with zero orders (zero-filled).

Includes trend metrics: month-over-month growth percentage, cumulative revenue,
and percentage of all-time location revenue.
{% enddocs %}

{% docs location_monthly_revenue__location_id %}
Primary key of the location from ref('locations').
{% enddocs %}

{% docs location_monthly_revenue__location_name %}
Human-readable store name from ref('locations').
{% enddocs %}

{% docs location_monthly_revenue__month_start %}
First day of the calendar month (e.g., '2024-01-01').
Use for sorting and filtering. This is part of the composite primary key.
{% enddocs %}

{% docs location_monthly_revenue__month %}
Formatted display label for the month (e.g., 'January 2024').
For display purposes only; use month_start for sorting and filtering.
{% enddocs %}

{% docs location_monthly_revenue__monthly_revenue %}
Sum of order_total for this location and month.
Zero if no orders were placed in that month.
{% enddocs %}

{% docs location_monthly_revenue__monthly_order_count %}
Count of orders for this location and month.
Zero if no orders were placed in that month.
{% enddocs %}

{% docs location_monthly_revenue__mom_revenue_growth_pct %}
Month-over-month revenue growth percentage.
Null for the first month of each location (no prior period to compare).
{% enddocs %}

{% docs location_monthly_revenue__cumulative_revenue %}
Running total of monthly_revenue for this location through the current month.
{% enddocs %}

{% docs location_monthly_revenue__pct_of_total_revenue %}
Monthly revenue as a percentage of the location's all-time total revenue.
Zero for locations with no all-time revenue.
{% enddocs %}
