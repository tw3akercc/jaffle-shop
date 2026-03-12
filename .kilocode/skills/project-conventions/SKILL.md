---
name: project-conventions
description: Project-specific dbt models, sources, packages, macros, and SQL style conventions
---

# Project-Specific dbt Conventions

## Existing Models (DO NOT RECREATE)

These models already exist in this project. Reference them with `{{ ref('model_name') }}` — do NOT create new models with the same names.

- `customers` (models/marts/customers.sql)
- `locations` (models/marts/locations.sql)
- `metricflow_time_spine` (models/marts/metricflow_time_spine.sql)
- `order_items` (models/marts/order_items.sql)
- `orders` (models/marts/orders.sql)
- `products` (models/marts/products.sql)
- `stg_customers` (models/staging/stg_customers.sql)
- `stg_locations` (models/staging/stg_locations.sql)
- `stg_order_items` (models/staging/stg_order_items.sql)
- `stg_orders` (models/staging/stg_orders.sql)
- `stg_products` (models/staging/stg_products.sql)
- `stg_supplies` (models/staging/stg_supplies.sql)
- `supplies` (models/marts/supplies.sql)

## Existing Sources

Use `{{ source('source_name', 'table_name') }}` to reference these:

- `ecom.raw_customers`
- `ecom.raw_items`
- `ecom.raw_orders`
- `ecom.raw_products`
- `ecom.raw_stores`
- `ecom.raw_supplies`

## Installed Packages

Use macros from these packages where applicable:

- `dbt-labs/dbt_utils` (1.3.3)
- `godatadriven/dbt_date` (0.17.1)
- `https://github.com/dbt-labs/dbt-audit-helper.git` (git)

## Custom Macros

These macros are available in this project:

- `macros/cents_to_dollars.sql`
- `macros/generate_schema_name.sql`

## Detected SQL Style (from existing codebase)

IMPORTANT: Match this project's existing style exactly.

- **Keyword casing**: lowercase
- **Indentation**: 4 spaces
- **Comma style**: trailing
- **Alias style**: explicit AS

Example from `models/staging/stg_order_items.sql`:
```sql
with

source as (

    select * from {{ source('ecom', 'raw_items') }}

),

renamed as (

    select

        ----------  ids
        id as order_item_id,
        order_id,
```
