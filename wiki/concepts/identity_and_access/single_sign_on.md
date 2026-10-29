---
title: Single Sign-On (SSO)
tags: [identity-and-access, access-management, saml, openid-connect]
sources: ["https://cheatsheetseries.owasp.org/cheatsheets/SAML_Security_Cheat_Sheet.html"]
created: 2026-10-29 14:09:46
updated: 2026-10-29 14:09:46
---

# Single Sign-On (SSO)

Single sign-on is an arrangement in which a user authenticates once, at a central **identity
provider (IdP)**, and is then admitted to many separate applications without logging in to each.
The applications trust the IdP's signed statement of who the user is, delivered through a
federation protocol, so [[concepts/identity_and_access/authentication|Authentication]] happens in
one place.

## Why It Matters

- **One strong login instead of many weak ones.** MFA, phishing-resistant authenticators, and
  password policy are enforced once at the IdP, not re-implemented by every application.
- **Offboarding in one place.** Disabling the IdP account stops new logins everywhere, the main
  reason organisations mandate SSO for business applications.
- **A concentrated risk.** The IdP becomes the single most valuable credential store; its
  compromise, or an application that validates its assertions badly, exposes everything behind it.

## Roles

| Role | SAML name | OIDC name | Job |
| --- | --- | --- | --- |
| Identity provider | IdP | OpenID provider (OP) | Authenticates the user and issues signed assertions or tokens |
| Application | Service provider (SP) | Relying party (RP) | Trusts the IdP and creates its own session from the assertion |
| User agent | Browser | Browser or app | Carries messages between the two by redirects and form posts |

## Protocols

| | SAML 2.0 | OpenID Connect |
| --- | --- | --- |
| Standardised | OASIS, 2005 | OpenID Foundation, 2014; ISO/IEC 26131:2024 |
| Payload | Signed XML assertion | Signed JWT (ID token) |
| Transport | Browser redirect and POST bindings | OAuth 2.0 redirects plus a back-channel token request |
| Strengths | Mature, universal in enterprise SaaS | Simpler, mobile- and API-friendly, pairs with OAuth access tokens |
| Weak spots | XML signature handling is easy to get wrong | Token validation mistakes, ID vs. access token confusion |

New applications usually choose [[concepts/identity_and_access/openid_connect|OpenID Connect (OIDC)]];
SAML remains common because so many enterprise applications and IdPs already support it. Inside a
Windows domain, Kerberos provides SSO for intranet services without either protocol.

## SP-Initiated vs. IdP-Initiated

- **SP-initiated** — the user starts at the application, which redirects to the IdP with a
  request and validates that the response answers it. This is the safer default.
- **IdP-initiated** — the user starts at the IdP's portal and is posted an unsolicited assertion.
  The application has no request to match it against, so the flow has no login CSRF protection;
  if it must be enabled, add replay detection and allow-list any `RelayState` redirect URL.

## Validating SAML Assertions

Most SAML breaches come from flawed validation rather than from the protocol. The OWASP checklist:

- **Verify the signature against a key configured for the IdP,** ignoring any key embedded in the
  message's `KeyInfo`, and require at least RSA-SHA256.
- **Make sure the signature covers the assertion actually used.** XML signature wrapping attacks
  insert a forged assertion beside a validly signed one; validate against local schemas and select
  elements by absolute path, not by tag-name search.
- **Check the audience** matches the SP's entity ID, and the `Destination` and `Recipient` match
  its assertion consumer URL.
- **Check the time window** (`NotBefore`, `NotOnOrAfter`) and keep it short.
- **Detect replay** of assertions, and keep SAML responses out of caches.

## Provisioning and Logout

SSO answers "may this person log in", not "does this person have an account". Two adjacent
problems remain:

- **Provisioning.** Accounts are created either just-in-time from assertion attributes at first
  login, or pushed ahead of time with SCIM (RFC 7643 and 7644), which also deprovisions them.
  Without deprovisioning, a disabled user's account and data linger in each application.
- **Logout.** Each application holds its own session, so disabling the IdP account does not end
  sessions that already exist; they last until they expire. SAML single logout and OIDC's
  front- and back-channel logout specifications propagate a logout, but support is uneven, which
  is why short application sessions matter.

## Related Concepts

- [[concepts/identity_and_access/authentication|Authentication]] — SSO centralises it at the IdP, where assurance levels and MFA are enforced
- [[concepts/identity_and_access/openid_connect|OpenID Connect (OIDC)]] — the modern SSO protocol, built on OAuth 2.0
- [[concepts/identity_and_access/json_web_token|JSON Web Token (JWT)]] — the format of OIDC assertions, and its validation pitfalls
- [[concepts/identity_and_access/authorization|Authorization]] — SSO establishes identity; each application still decides what that identity may do

## References

- [OWASP SAML Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/SAML_Security_Cheat_Sheet.html)
- [OASIS Security Services (SAML) Technical Committee](https://www.oasis-open.org/committees/security/)
