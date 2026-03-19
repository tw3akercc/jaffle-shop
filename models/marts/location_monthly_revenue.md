{% docs location_monthly_revenue %}
Monthly revenue aggregation by location with month-over-month growth, cumulative revenue,
and percentage of location total. Grain: one row per location per month from opened_date
through current month, including months with zero orders.
{% enddocs %}

{% docs location_monthly_revenue__location_id %}
Location identifier referencing the locations mart.
{% enddocs %}

{% docs location_monthly_revenue__location_name %}
Human-readable name of the location.
{% enddocs %}

{% docs location_monthly_revenue__month %}
First day of the calendar month for this aggregation period.
{% enddocs %}

{% docs location_monthly_revenue__monthly_revenue %}
Pre-tax revenue (subtotal) for the location in this month. Zero for months with no orders.
{% enddocs %}

{% docs location_monthly_revenue__monthly_order_count %}
Count of orders placed at the location in this month. Zero for months with no orders.
{% enddocs %}

{% docs location_monthly_revenue__mom_revenue_growth_pct %}
Month-over-month revenue growth percentage.
Calculated as (current_month - prior_month) / prior_month * 100.
Null for the location's first month or when prior month revenue is zero.
{% enddocs %}

{% docs location_monthly_revenue__cumulative_revenue %}
Running sum of monthly_revenue for this location through this month.
{% enddocs %}

{% docs location_monthly_revenue__pct_of_location_total %}
This month's revenue as a percentage of the location's all-time total revenue.
{% enddocs %}
