{% docs monthly_revenue_report %}
Monthly revenue report providing analytics per location for the finance team.
Grain: One row per location per calendar month, only for months where that location had at least one order.

Includes key metrics:
- Monthly revenue and order counts
- Month-over-month revenue growth percentage
- Cumulative running revenue totals
- Location total revenue (all time)
- Revenue contribution percentage (month vs. total)
{% enddocs %}

{% docs monthly_revenue_report__location_id %}
The unique identifier for the location (foreign key to locations).
{% enddocs %}

{% docs monthly_revenue_report__location_name %}
The human-readable name of the location.
{% enddocs %}

{% docs monthly_revenue_report__month %}
The calendar month in YYYY-MM-01 format representing the first day of the month.
{% enddocs %}

{% docs monthly_revenue_report__monthly_revenue %}
The total pre-tax revenue (sum of subtotal) for the location in the given month.
{% enddocs %}

{% docs monthly_revenue_report__monthly_order_count %}
The count of distinct orders placed at the location in the given month.
{% enddocs %}

{% docs monthly_revenue_report__mom_revenue_growth_pct %}
Month-over-month revenue growth percentage calculated as:
((current month revenue - previous month revenue) / previous month revenue) * 100.
NULL for the first recorded month for each location.
{% enddocs %}

{% docs monthly_revenue_report__cumulative_revenue %}
Running sum of monthly revenue for the location, ordered by month.
Represents total revenue accumulated from the first month through the current month.
{% enddocs %}

{% docs monthly_revenue_report__location_total_revenue %}
Total revenue for the location across all time (all months).
Same value repeated for all months of a given location.
{% enddocs %}

{% docs monthly_revenue_report__revenue_contribution_pct %}
Percentage of the month's revenue relative to the location's total revenue across all time.
Calculated as: (monthly_revenue / location_total_revenue) * 100.
{% enddocs %}
