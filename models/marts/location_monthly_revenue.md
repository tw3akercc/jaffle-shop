{% docs location_monthly_revenue %}
Monthly revenue summary aggregated by store location for finance team trend analysis. Grain: one row per location per calendar month (only months with at least one order).
{% enddocs %}

{% docs location_monthly_revenue__location_id %}
FK to `locations`. The unique identifier for the store location.
{% enddocs %}

{% docs location_monthly_revenue__location_name %}
Human-readable store name from the locations dimension table.
{% enddocs %}

{% docs location_monthly_revenue__revenue_month %}
First day of the calendar month. Derived by truncating `ordered_at` to month level.
{% enddocs %}

{% docs location_monthly_revenue__monthly_order_count %}
Orders placed at this location in the month. Always >= 1 since months with no orders are excluded.
{% enddocs %}

{% docs location_monthly_revenue__monthly_revenue %}
Sum of `order_total` (tax-inclusive) for the month. This represents actual cash collected from customers.
{% enddocs %}

{% docs location_monthly_revenue__monthly_revenue_pretax %}
Sum of `subtotal` (pre-tax) for the month. Revenue before tax is applied.
{% enddocs %}

{% docs location_monthly_revenue__mom_revenue_growth_pct %}
Month-over-month revenue change as a percentage: `(current_month - prior_month) / prior_month * 100`. Will be null for a location's first month, which is expected and acceptable.
{% enddocs %}

{% docs location_monthly_revenue__cumulative_revenue %}
Running sum of `monthly_revenue` through current month, per location. Shows total revenue accumulated from the location's first month through the current month.
{% enddocs %}

{% docs location_monthly_revenue__pct_of_location_total_revenue %}
This month's revenue as a percentage of the location's all-time revenue across all months: `monthly_revenue / all-time location revenue * 100`.
{% enddocs %}