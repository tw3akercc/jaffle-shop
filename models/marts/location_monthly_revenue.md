{% docs location_monthly_revenue %}
Pre-aggregated monthly revenue table at the location x month grain for finance trend analysis. One row per location per calendar month in which at least one order was placed. No calendar spine — rows exist only when orders exist.
{% enddocs %}

{% docs location_monthly_revenue__location_id %}
Foreign key to the locations mart. Identifies the store location for this row.
{% enddocs %}

{% docs location_monthly_revenue__location_name %}
Human-readable name of the store location, joined from ref('locations').
{% enddocs %}

{% docs location_monthly_revenue__revenue_month %}
The calendar month (truncated to the first day of the month) in which the orders were placed.
{% enddocs %}

{% docs location_monthly_revenue__monthly_revenue %}
Sum of pre-tax order subtotals (in dollars) for this location in this month. Uses subtotal rather than order_total for apples-to-apples comparisons across locations with different tax rates.
{% enddocs %}

{% docs location_monthly_revenue__monthly_order_count %}
Count of distinct orders placed at this location in this month. Always >= 1; zero-order months are excluded.
{% enddocs %}

{% docs location_monthly_revenue__revenue_mom_growth_pct %}
Month-over-month revenue growth rate: (monthly_revenue - prior_month_revenue) / prior_month_revenue. NULL for a location's first month (no prior month exists). Not coalesced to 0 or 100.
{% enddocs %}

{% docs location_monthly_revenue__cumulative_revenue %}
Running cumulative sum of monthly_revenue for this location, ordered by revenue_month. Monotonically non-decreasing per location.
{% enddocs %}

{% docs location_monthly_revenue__pct_of_location_revenue %}
This month's share of the location's all-time revenue: monthly_revenue / sum(monthly_revenue) over all months for this location. Values are in the range (0, 1] and sum to 1.0 per location.
{% enddocs %}
