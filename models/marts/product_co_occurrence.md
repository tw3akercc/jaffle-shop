{% docs product_co_occurrence %}
Product co-occurrence analysis for merchandising insights. Grain: one row per unique, unordered product pair across all orders.
This model identifies which products are most frequently ordered together, providing actionable insights for menu optimization and potential combo/bundle deals.
{% enddocs %}

{% docs product_co_occurrence__product_id_left %}
The product ID for the left product in the pair (lower ID to ensure uniqueness).
{% enddocs %}

{% docs product_co_occurrence__product_id_right %}
The product ID for the right product in the pair (higher ID to ensure uniqueness).
{% enddocs %}

{% docs product_co_occurrence__product_name_left %}
The name of the left product in the pair.
{% enddocs %}

{% docs product_co_occurrence__product_name_right %}
The name of the right product in the pair.
{% enddocs %}

{% docs product_co_occurrence__product_type_left %}
The type/category of the left product in the pair.
{% enddocs %}

{% docs product_co_occurrence__product_type_right %}
The type/category of the right product in the pair.
{% enddocs %}

{% docs product_co_occurrence__co_occurrence_count %}
The count of distinct orders where both products appeared together.
{% enddocs %}

{% docs product_co_occurrence__product_left_order_count %}
The count of distinct orders containing the left-side product.
{% enddocs %}

{% docs product_co_occurrence__product_right_order_count %}
The count of distinct orders containing the right-side product.
{% enddocs %}

{% docs product_co_occurrence__support_pct %}
The co_occurrence_count divided by the total number of distinct orders, expressed as a percentage.
Indicates how frequently this product pair appears together across all orders.
{% enddocs %}
