# Install
Use the following command for installation: `pip install dbt-core dbt-databricks`
# Configuring dbt-databricks
# Connecting to Databricks
## Parameters

| **Field**            | **Required**               | **Description**                                                                                                 |
| -------------------- | -------------------------- | --------------------------------------------------------------------------------------------------------------- |
| `host`               | Yes                        | The hostname of your cluster.  <br>Don't include the `http://` or `https://` prefix.                            |
| `http_path`          | Yes                        | The http path to your SQL Warehouse or all-purpose cluster.                                                     |
| `schema`             | Yes                        | The name of a schema within your cluster's catalog.                                                             |
| `token`              | Yes (Only for Token-based) | The Personal Access Token (PAT) to connect to Databricks.                                                       |
| `client_id`          | Yes (Only for OAuth-based) | The client ID for your Databricks OAuth application.                                                            |
| `client_secret`      | Yes (Only for OAuth-based) | The client secret for your Databricks OAuth application.                                                        |
| `auth_type`          | Yes (Only for OAuth-based) | The type of authorization needed to connect to Databricks.                                                      |
| `threads`            | No                         | The number of threads dbt should use (default is `1`)                                                           |
| `connect_retries`    | No                         | The number of times dbt should retry the connection to Databricks (default is `1`)                              |
| `connect_timeout`    | No                         | How many seconds before the connection to Databricks should timeout (default behavior is no timeouts)           |
| `session_properties` | No                         | This sets the Databricks session properties used in the connection. Execute `SET -v` to see available options\| |

## Token-based authentication
**`~/.dbt/profiles.yml`**
```yaml
your_profile_name:
  target: dev
  outputs:
    dev:
      type: databricks
      catalog: CATALOG_NAME #optional catalog name if you are using Unity Catalog]
      schema: SCHEMA_NAME # Required
      host: YOURORG.databrickshost.com # Required
      http_path: /SQL/YOUR/HTTP/PATH # Required
      token: dapiXXXXXXXXXXXXXXXXXXXXXXX # Required Personal Access Token (PAT) if using token-based authentication
      threads: 1_OR_MORE  # Optional, default 1
```
## OAuth client-based authentication
**`~/.dbt/profiles.yml`**
```yaml
your_profile_name:
  target: dev
  outputs:
    dev:
      type: databricks
      catalog: CATALOG_NAME #optional catalog name if you are using Unity Catalog
      schema: SCHEMA_NAME # Required
      host: YOUR_ORG.databrickshost.com # Required
      http_path: /SQL/YOUR/HTTP/PATH # Required
      auth_type: oauth # Required if using OAuth-based authentication
      client_id: OAUTH_CLIENT_ID # The ID of your OAuth application. Required if using OAuth-based authentication
      client_secret: XXXXXXXXXXXXXXXXXXXXXXXXXXX # OAuth client secret. # Required if using OAuth-based authentication
      threads: 1_OR_MORE  # Optional, default 1
```
# Reference
1. [Databricks Setup](https://docs.getdbt.com/docs/core/connect-data-platform/databricks-setup)