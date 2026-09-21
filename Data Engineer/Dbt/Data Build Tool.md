# Definition
Dbt (data build tool) is a command-line tool that enables data engineers and analysts to transform data in their data warehouses more effectively. It focuses on the "T" (transform) in ELT (Extract, Load, Transform) pipelines. dbt doesn't extract or load data; it assumes that data has already been loaded into your warehouse. Instead, dbt helps you write, test, and document the SQL transformations that clean, model, and aggregate your data.

# Install

# Adapters
An adapter is a plugin that translates dbt's generic SQL into the specific dialect of your chosen database. This allows you to write consistent dbt code regardless of the underlying data platform.
## Install adapter
Install from PyPI using: `pip install dbt-<adapter_name>`
For example, to install the Snowflake adapter: `pip install dbt-snowflake`
## How to connect
When you install dbt Core, you'll also need to install the specific adapter for your database, connect to dbt Core, and set up a `profiles.yml` file.
## Trusted Adapters
- [[Databricks Adapter]]
- [[Snowflake Adapter]]
- [[BigQuery Adapter]]