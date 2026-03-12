---
name: dbt-best-practices
description: dbt SQL conventions, naming, CTE structure, ref/source usage, and testing standards
---

# dbt Best Practices

You are generating dbt models. Follow these conventions exactly.

## 0. Spec Compliance (HIGHEST PRIORITY)

When the task specifies exact names, use them **verbatim**:
- **Model file names**: If the spec says "model name: product_pair_analysis", create `product_pair_analysis.sql` — do NOT rename to `product_co_occurrence` or anything else.
- **Column names**: If the spec lists `product_a_id, product_b_id, cooccurrence_count`, use those exact names — do NOT rename to `product_id_left`, `co_occurrence_count`, etc.
- **All explicitly requested fields**: If the spec says "include product_type for both sides", you MUST include those columns. Do not omit fields that were explicitly requested.

The spec is the source of truth. Do not "improve" names that were explicitly chosen.

## 1. Naming Conventions

- Use **snake_case** for all model names. No camelCase, no dots, no hyphens.
- Use **plural** form for model names (e.g., `customers`, `orders`, not `customer`).
- Layer prefixes are mandatory:
  - `stg_{source}_{table}` — Staging models (1:1 with source, rename/recast only)
  - `int_{concept}_{verb}` — Intermediate models (joins, business logic)
  - `dim_{entity}` — Dimension models (entity attributes)
  - `fct_{event}` — Fact models (events, transactions)
  - `mart_{domain}_{concept}` — Mart models (aggregated, business-level)
- Primary key naming: use `{entity}_id` consistently (e.g., `customer_id`, `order_id`).

## 2. ref() and source() Usage

- **ALWAYS** use `{{ ref('model_name') }}` to reference other dbt models.
- **ALWAYS** use `{{ source('source_name', 'table_name') }}` for raw data tables.
- **NEVER** hardcode table names like `schema.table_name` or `database.schema.table` in FROM or JOIN clauses.
- `source()` is acceptable alongside `ref()` — use `source()` for raw tables defined in `sources.yml`.
- Place all ref/source calls in **import CTEs** at the top of the model for clarity.

## 3. CTE Structure

Every model should follow this structure:

```sql
{{ config(materialized='view') }}

with

source_data as (
    select * from {{ source('source_name', 'table_name') }}
),

renamed as (
    select
        id as customer_id,
        first_name,
        last_name,
        email,
        created_at
    from source_data
),

final as (
    select * from renamed
)

select * from final
```

Rules:
- **Import CTEs first**: one CTE per referenced model/source, named after the model.
- **Logical CTEs second**: transformation steps with descriptive names.
- **Final CTE last**: prefix with `final as (`.
- **Always end with** `select * from final`.
- Separate CTEs with a blank line before each CTE name.

## 4. SQL Style

- **Indentation**: 4 spaces (no tabs).
- **Keywords**: lowercase (`select`, `from`, `where`, `join`, `on`, `group by`, `order by`, `as`, `and`, `or`, `not`, `in`, `between`, `case`, `when`, `then`, `else`, `end`).
- **Commas**: trailing (comma at end of line, NOT leading).
- **Aliases**: always use the `as` keyword explicitly (`count(*) as order_count`, not `count(*) order_count`).
- **Column listing**: one column per line in `select` statements.
- **Explicit columns**: never use `select *` in final/mart models (staging imports are acceptable).
- **Comments**: use `--` for single-line comments (not `/* */`).
- **Line length**: keep lines under 80 characters when reasonable.
- **CTEs over subqueries**: always prefer CTEs for readability.
- **Table aliases**: use descriptive names (use `customers` not `c`, use `orders` not `o`).
- **Joins**: prefer `left join` over `inner join` for defensive coding — unless the spec explicitly requires inner join.

## 5. Materializations

- **Staging models**: `materialized='view'` (default, lightweight).
- **Intermediate models**: `materialized='ephemeral'` (unless debugging needed, then `'view'`).
- **Dimension and fact models**: `materialized='table'`.
- **Mart models**: `materialized='table'`.
- **Incremental**: only when business logic justifies it (large event tables, append-only patterns). Not by default.
- Always declare materialization in model config: `{{ config(materialized='table') }}`.

## 6. Tests

- **Every model** must have a corresponding entry in `schema.yml` with tests.
- **Primary keys**: always add `unique` and `not_null` tests.
- **Foreign keys**: add `relationships` tests to verify referential integrity.
- **Enums/status fields**: add `accepted_values` tests where applicable.
- Place schema tests in `schema.yml` files alongside the models (same directory).

Example `schema.yml` (descriptions reference doc blocks — see Section 7):
```yaml
version: 2

models:
  - name: stg_orders
    description: '{{ doc("stg_orders") }}'
    columns:
      - name: order_id
        description: '{{ doc("stg_orders__order_id") }}'
        tests:
          - unique
          - not_null
      - name: customer_id
        description: '{{ doc("stg_orders__customer_id") }}'
        tests:
          - not_null
          - relationships:
              to: ref('stg_customers')
              field: customer_id
      - name: status
        description: '{{ doc("stg_orders__status") }}'
        tests:
          - accepted_values:
              values: ['placed', 'shipped', 'completed', 'returned']
```

## 7. Documentation (Doc Blocks)

Use **doc block macros** for all model and column documentation. Do NOT write descriptions inline in `schema.yml`.

### How it works:
1. Create a markdown file alongside the model (e.g., `models/marts/product_pair_analysis.md`)
2. Define doc blocks in the `.md` file using `{% docs block_name %}...{% enddocs %}`
3. Reference them in `schema.yml` with `description: '{{ doc("block_name") }}'`

### Doc block file example (`models/marts/product_pair_analysis.md`):
```markdown
{% docs product_pair_analysis %}
Product pair co-occurrence analysis for merchandising. Grain: one row per unique product pair across all orders.
{% enddocs %}

{% docs product_pair_analysis__product_a_id %}
The product ID for the first product in the pair (lower ID to ensure uniqueness).
{% enddocs %}

{% docs product_pair_analysis__cooccurrence_count %}
Number of distinct orders containing both products.
{% enddocs %}
```

### Corresponding `schema.yml`:
```yaml
models:
  - name: product_pair_analysis
    description: '{{ doc("product_pair_analysis") }}'
    columns:
      - name: product_a_id
        description: '{{ doc("product_pair_analysis__product_a_id") }}'
        tests:
          - not_null
      - name: cooccurrence_count
        description: '{{ doc("product_pair_analysis__cooccurrence_count") }}'
```

### Rules:
- **Model-level doc**: name it `{model_name}` — include the grain.
- **Column-level docs**: name them `{model_name}__{column_name}` (double underscore).
- **One `.md` file per model**, placed in the same directory as the model.
- **Every column** must have a doc block — no inline descriptions in YAML.
- Document any non-obvious transformations with inline SQL comments in the `.sql` file.

## 8. Before Writing Code

Before creating any new model:
1. **Search the existing codebase** for models that might already cover the requirement.
2. **Check source definitions** in `sources.yml` or `schema.yml` files.
3. **Review naming conventions** used in the project (look at existing model prefixes).
4. **Check for existing macros** in the `macros/` directory that you should reuse.
5. **Check installed packages** (e.g., dbt_utils) for useful macros like `generate_surrogate_key`, `pivot`, `union_relations`.

Do NOT recreate models that already exist. If a model exists, reference it with `{{ ref('model_name') }}`.
