---
title: OAuth (Open Authorization)
tags: [identity-and-access, api-protocols, access-control, oauth, stub]
created: 2026-10-26 23:17:48
updated: 2026-10-26 23:21:14
---

# OAuth (Open Authorization)

OAuth is an open standard for delegated authorization. It lets an application access a resource
on a user's or a service's behalf through scoped, expiring access tokens, so the application never
handles the account password. OAuth 2.0 is the version in common use; OpenID Connect builds
authentication on top of it, and the standard secures most of the HTTP APIs in
[[concepts/software_architecture/api_integration_protocols|API and Integration Protocols]].

## Related Concepts

- [[concepts/software_architecture/api_integration_protocols|API and Integration Protocols]] — the interfaces OAuth tokens most often protect
- [[concepts/data_governance/data_security|Data Security]] — OAuth scopes are one implementation of the access-control models described there
- [[concepts/ai_engineering/model_context_protocol|Model Context Protocol (MCP)]] — specifies OAuth 2.1 for authorizing clients against remote servers
- [[concepts/data_engineering/dbt/dbt_databricks_adapter|dbt-databricks Adapter]] — a worked example of the machine-to-machine and user-to-machine flows
