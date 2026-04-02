{% docs location_revenue_monthly %}
Monthly revenue aggregation by store location for the finance team's Power BI dashboard. Grain: one row per location_id per calendar month in which at least one order was placed.
{% enddocs %}

{% docs location_revenue_monthly__location_id %}
Foreign key to the locations dimension. Identifies the store location for this row.
{% enddocs %}

{% docs location_revenue_monthly__location_name %}
Human-readable store display name, joined from the locations mart.
{% enddocs %}

{% docs location_revenue_monthly__revenue_month %}
First day of the calendar month, derived by truncating ordered_at to month precision.
{% enddocs %}

{% docs location_revenue_monthly__monthly_revenue %}
Sum of order_total for all orders placed at this location during the calendar month. Values are in dollars (cents-to-dollars conversion applied upstream in stg_orders).
{% enddocs %}

{% docs location_revenue_monthly__monthly_order_count %}
Count of orders placed at this location during the calendar month. Always at least 1 since months with no orders are excluded.
{% enddocs %}

{% docs location_revenue_monthly__mom_revenue_growth_pct %}
Month-over-month revenue growth percentage: (monthly_revenue - prior month revenue) / prior month revenue * 100, rounded to 2 decimal places. Null for a location's first month in the dataset (no prior row exists for lag).
{% enddocs %}

{% docs location_revenue_monthly__cumulative_revenue %}
Running total of monthly_revenue for this location from its earliest month through the current row, inclusive. Computed as a window sum with rows between unbounded preceding and current row.
{% enddocs %}

{% docs location_revenue_monthly__pct_of_location_total_revenue %}
This month's revenue as a percentage of the location's all-time total revenue, rounded to 2 decimal places. Sum of this column per location rounds to 100.00.
{% enddocs %}
