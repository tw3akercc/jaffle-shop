{% docs location_revenue_monthly %}
Monthly location-level revenue mart. Grain: one row per (location_id, month). Months with zero orders for a location are omitted. Includes month-over-month growth, cumulative revenue, and each month's share of a store's all-time revenue.
{% enddocs %}

{% docs location_revenue_monthly__location_id %}
Foreign key to the locations mart. Identifies the store associated with this row.
{% enddocs %}

{% docs location_revenue_monthly__location_name %}
Human-readable store name, denormalized from the locations mart for BI convenience.
{% enddocs %}

{% docs location_revenue_monthly__month %}
First day of the calendar month, derived by truncating ordered_at to month granularity.
{% enddocs %}

{% docs location_revenue_monthly__monthly_order_count %}
Number of orders placed at this location during the month. Always greater than zero — months with no orders are excluded.
{% enddocs %}

{% docs location_revenue_monthly__monthly_subtotal %}
Sum of order subtotals (pre-tax) for all orders at this location during the month, in dollars.
{% enddocs %}

{% docs location_revenue_monthly__monthly_order_total %}
Sum of order totals (including tax) for all orders at this location during the month, in dollars.
{% enddocs %}

{% docs location_revenue_monthly__mom_subtotal_growth_pct %}
Month-over-month percentage change in monthly_subtotal for this location. Calculated as (current - prior) / prior. NULL for the location's first month or when the prior month subtotal is zero.
{% enddocs %}

{% docs location_revenue_monthly__mom_order_total_growth_pct %}
Month-over-month percentage change in monthly_order_total for this location. Calculated as (current - prior) / prior. NULL for the location's first month or when the prior month order total is zero.
{% enddocs %}

{% docs location_revenue_monthly__cumulative_subtotal %}
Running sum of monthly_subtotal for this location from its first month through the current month.
{% enddocs %}

{% docs location_revenue_monthly__cumulative_order_total %}
Running sum of monthly_order_total for this location from its first month through the current month.
{% enddocs %}

{% docs location_revenue_monthly__pct_of_total_subtotal %}
This month's monthly_subtotal as a fraction of the location's all-time total subtotal. Values sum to 1.0 per location across all months.
{% enddocs %}

{% docs location_revenue_monthly__pct_of_total_order_total %}
This month's monthly_order_total as a fraction of the location's all-time total order revenue. Values sum to 1.0 per location across all months.
{% enddocs %}
