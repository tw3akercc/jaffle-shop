---
workflow_key: jaffle-shop-default
name: Jaffle Shop Default Workflow
version: 1
runtime: codex
labels: [jaffle-shop, dbt, analytics-engineering]
auto_merge: false
auto_deploy: false
---

# Jaffle Shop Default Workflow

Use this workflow for dbt development tasks in the Jaffle Shop repository unless a task-specific spec says otherwise.

## Operating role

You are implementing changes in a dbt analytics project. Read this workflow, the task description, and the current repository files before editing. Prefer small, reviewable changes that preserve the existing dbt project structure.

## Standard implementation loop

1. Inspect the relevant models, seeds, macros, tests, and project configuration before editing.
2. Make the smallest coherent change that satisfies the task.
3. Add or update dbt tests when behavior, model grain, assumptions, or data quality expectations change.
4. Run focused verification when available, preferring:
   - `dbt parse`
   - `dbt compile`
   - `dbt build --select <changed resources>+`
5. If the task changes dependencies, profiles, warehouse assumptions, or seed-loading behavior, include setup notes and the exact verification command that was run.
6. Open a PR with a concise summary, verification evidence, risk notes, and any manual follow-up required.

## dbt quality bar

- Keep model names, source names, and test names consistent with the existing project conventions.
- Do not make warehouse-specific assumptions unless the task or existing project configuration already does.
- Treat seed data and generated DuckDB artifacts as local development support unless the task explicitly asks to change them.
- Avoid committing generated `target/`, `logs/`, virtual environment, or local database artifacts.
