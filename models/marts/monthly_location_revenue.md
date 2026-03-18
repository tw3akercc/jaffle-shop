{% docs monthly_location_revenue %}
Monthly revenue report for the finance team, enabling analysis of store performance trends over time. One row per unique combination of location and calendar month.
{% enddocs %}

{% docs monthly_location_revenue__location_id %}
The unique identifier for the location.
{% enddocs %}
{% docs monthly_location_revenue__location_name %}
The human-readable name of the location.
{% enddocs %}
{% docs monthly_location_revenue__report_month %}
The first day of the month for which revenue is reported (e.g., '2023-01-01').
{% enddocs %}
{% docs monthly_location_revenue__monthly_revenue %}
The total revenue (subtotal, pre-tax) for the location in the given month.
{% enddocs %}
{% docs monthly_location_revenue__monthly_order_count %}
The count of distinct orders for the location in the given month.
{% enddocs %}
{% docs monthly_location_revenue__month_over_month_growth_pct %}
The percentage growth in revenue compared to the previous month. NULL for the first month of each location.
{% enddocs %}
{% docs monthly_location_revenue__cumulative_revenue %}
The running total of revenue for the location from the earliest month to the current month.
{% enddocs %}
{% docs monthly_location_revenue__monthly_revenue_pct_of_total %}
The percentage of the location's total all-time revenue that occurred in this month. Sum of all values for a location equals 100%.
{% enddocs %}
