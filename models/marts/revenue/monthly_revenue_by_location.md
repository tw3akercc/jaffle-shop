{% docs monthly_revenue_by_location %}
Monthly revenue analysis broken down by store location. Grain: one row per (location_id, year, month) combination.
{% enddocs %}

{% docs monthly_revenue_by_location__location_id %}
Foreign key to the locations dimension table.
{% enddocs %}

{% docs monthly_revenue_by_location__location_name %}
Store name.
{% enddocs %}

{% docs monthly_revenue_by_location__year %}
Calendar year of the revenue period.
{% enddocs %}

{% docs monthly_revenue_by_location__month %}
Calendar month of the revenue period (1-12).
{% enddocs %}

{% docs monthly_revenue_by_location__monthly_revenue %}
Sum of order_total for the month in USD.
{% enddocs %}

{% docs monthly_revenue_by_location__order_count %}
Count of distinct orders for the month.
{% enddocs %}

{% docs monthly_revenue_by_location__mom_revenue_growth_pct %}
Month-over-month revenue growth percentage. NULL for the first month per location.
{% enddocs %}

{% docs monthly_revenue_by_location__cumulative_revenue %}
Running total of monthly_revenue for this location in chronological order.
{% enddocs %}

{% docs monthly_revenue_by_location__revenue_pct_of_location_total %}
Monthly revenue as a percentage of all-time location revenue.
{% enddocs %}
