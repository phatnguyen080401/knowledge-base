---
title: OpenID Connect (OIDC)
tags: [identity-and-access, access-management, openid-connect, oauth, jwt]
sources: ["https://openid.net/specs/openid-connect-core-1_0.html", "https://www.iso.org/standard/89056.html"]
created: 2026-10-29 14:09:46
updated: 2026-10-29 14:09:46
---

# OpenID Connect (OIDC)

OpenID Connect is an identity layer on top of [[concepts/identity_and_access/oauth|OAuth (Open Authorization)]]
2.0 that lets an application verify who a user is, based on the
[[concepts/identity_and_access/authentication|Authentication]] performed by an authorization
server, and obtain basic profile claims about them. Its core addition is the **ID token**, a signed
[[concepts/identity_and_access/json_web_token|JSON Web Token (JWT)]] addressed to the application.

## Why It Matters

- **OAuth alone cannot log anyone in.** An access token authorizes API calls; it says nothing
  reliable to the client about who the user is. OIDC fills exactly that gap.
- **It is the modern federation protocol.** Social login, enterprise
  [[concepts/identity_and_access/single_sign_on|Single Sign-On (SSO)]] for new applications, and
  mobile sign-in all run on it.
- **It is now an international standard.** OpenID Connect Core 1.0, with errata set 2, was
  published as ISO/IEC 26131:2024.

## What OIDC Adds to OAuth 2.0

| Addition | What it does |
| --- | --- |
| `openid` scope | Requesting it turns an OAuth request into an OIDC authentication request |
| ID token | A signed JWT stating who authenticated, to which client, when, and how |
| UserInfo endpoint | An OAuth-protected API returning claims about the user |
| Standard scopes and claims | `profile`, `email`, `address`, and `phone` request well-known claims such as `name` and `email` |
| Discovery | A metadata document at `/.well-known/openid-configuration` listing endpoints and supported algorithms |
| JWKS | The provider's published signing keys, used to verify ID tokens |

The OAuth roles get new names: the authorization server is the **OpenID provider (OP)** and the
client is the **relying party (RP)**.

## The ID Token

| Claim | Required | Meaning |
| --- | --- | --- |
| `iss` | Yes | Issuer: the provider's HTTPS identifier |
| `sub` | Yes | Subject: a stable, never-reassigned identifier for the user at that issuer |
| `aud` | Yes | Audience: must contain the RP's `client_id` |
| `exp` | Yes | Expiry time |
| `iat` | Yes | Issue time |
| `nonce` | When sent | Echoes the RP's request value, binding the token to that login and preventing replay |
| `auth_time` | When requested | When the user actually authenticated |
| `acr`, `amr` | Optional | Assurance class achieved and authentication methods used, e.g. MFA |
| `azp` | Optional | The authorized party, when it differs from the audience |

ID tokens must be signed with JWS; the `none` algorithm is allowed only in a narrow case the RP
explicitly registers for.

> [!warning] Identify users by `iss` plus `sub`, never by email
> Email addresses change and can be reassigned or unverified. The pair of issuer and subject is
> the only identifier the specification guarantees to be stable and unique.

## Validating an ID Token

The RP must, per OIDC Core section 3.1.3.7:

1. Check that `iss` exactly matches the expected issuer.
2. Check that `aud` contains its own `client_id` and no untrusted audiences, and check `azp` if
   present.
3. Verify the signature with the issuer's published keys, using the algorithm it expects.
4. Reject the token if the current time is past `exp`, and use `iat` to bound its age.
5. Check that `nonce` matches the value it sent.
6. Check `acr` and `auth_time` if it requested them.

When the RP receives the ID token directly from the token endpoint over TLS in the authorization
code flow, TLS server validation may stand in for the signature check.

## Flows

| Flow | `response_type` | Where tokens come from |
| --- | --- | --- |
| Authorization code | `code` | All tokens from the token endpoint; the recommended default, with PKCE |
| Implicit | `id_token`, `id_token token` | Directly from the authorization endpoint; `nonce` required |
| Hybrid | `code id_token`, `code token`, `code id_token token` | A code plus some tokens from the authorization endpoint, the rest from the token endpoint |

The authorization code flow is the one to use for new applications, in line with the OAuth
security guidance that discourages returning access tokens from the authorization endpoint.

## ID Token vs. Access Token

| | ID token | Access token |
| --- | --- | --- |
| Audience | The client (RP) | The resource server (API) |
| Purpose | Prove who logged in | Authorize API calls |
| Format | Always a JWT | Unspecified: opaque or JWT |
| Who validates it | The client | The resource server |
| Send it to an API? | No | Yes |

Mixing them up is the classic OIDC mistake: an API that accepts ID tokens as credentials, or a
client that treats an access token as proof of login.

## Workload Identity Tokens

OIDC tokens are not only for humans. CI platforms such as GitHub Actions mint a short-lived ID
token for each job, with claims naming the repository, branch, and workflow; a cloud provider
trusts that issuer and exchanges the token for short-lived cloud credentials. This is how keyless
deployment works in
[[concepts/data_engineering/dbt/deploy_dbt_cloud_run_github_actions|Deploy dbt and Elementary to Cloud Run with GitHub Actions]],
and why pinning the trust condition to specific claims is the security-critical step.

## Related Concepts

- [[concepts/identity_and_access/oauth|OAuth (Open Authorization)]] — the authorization framework OIDC extends
- [[concepts/identity_and_access/authentication|Authentication]] — what the ID token reports on, including assurance via `acr` and `amr`
- [[concepts/identity_and_access/json_web_token|JSON Web Token (JWT)]] — the ID token's format, and the validation rules it inherits
- [[concepts/identity_and_access/single_sign_on|Single Sign-On (SSO)]] — OIDC and SAML are the two federation protocols SSO runs on
- [[concepts/data_engineering/dbt/deploy_dbt_cloud_run_github_actions|Deploy dbt and Elementary to Cloud Run with GitHub Actions]] — OIDC workload tokens used for keyless CI authentication

## References

- [OpenID Connect Core 1.0](https://openid.net/specs/openid-connect-core-1_0.html)
- [ISO/IEC 26131:2024, OpenID Connect Core 1.0 incorporating errata set 2](https://www.iso.org/standard/89056.html)
- [OpenID Connect Discovery 1.0](https://openid.net/specs/openid-connect-discovery-1_0.html)
