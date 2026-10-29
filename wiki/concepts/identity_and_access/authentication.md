---
title: Authentication
tags: [identity-and-access, access-management, webauthn]
sources: ["https://pages.nist.gov/800-63-4/sp800-63b.html"]
created: 2026-10-29 13:31:59
updated: 2026-10-29 14:09:46
---

# Authentication

Authentication (often shortened to AuthN) is the process of verifying that a user, device, or
service is who it claims to be, by checking one or more factors: something it knows (a password),
something it has (a key, token, or device), or something it is (a biometric). It answers "who are
you?" and always comes before [[concepts/identity_and_access/authorization|Authorization]], which
decides what that verified identity may do.

## Why It Matters

- **Every authorization decision inherits its strength.** A perfect permission model protects
  nothing if an attacker can log in as the user it trusts.
- **Credentials are the cheapest attack.** Phishing, credential stuffing with breached passwords,
  and leaked long-lived keys need no software vulnerability at all.
- **Strength is a dial, not a switch.** The assurance a system needs depends on what an
  impersonator could do, which is why NIST grades authentication into levels rather than
  prescribing one method.

## Authentication vs. Authorization

| | Authentication (AuthN) | Authorization (AuthZ) |
| --- | --- | --- |
| Question | Who are you? | What may you do? |
| Input | Credentials, authenticators | A verified identity, the resource, the action, policy |
| Output | An identity, often as a session or token | Allow or deny |
| Failure code in HTTP | `401 Unauthorized` (a misnomer: it means unauthenticated) | `403 Forbidden` |
| Typical standard | [[concepts/identity_and_access/openid_connect\|OpenID Connect (OIDC)]], SAML, WebAuthn | [[concepts/identity_and_access/oauth\|OAuth (Open Authorization)]] scopes, RBAC, ABAC |

## Authentication Factors

| Factor | Examples | Main weakness |
| --- | --- | --- |
| Knowledge (something you know) | Password, PIN, security question | Guessable, reused across sites, phishable |
| Possession (something you have) | Hardware security key, authenticator app (TOTP), smart card, phone receiving a code | Loss or theft; codes can still be phished |
| Inherence (something you are) | Fingerprint, face | Not secret and not revocable, so used to unlock a local authenticator rather than as a remote credential |

**Multi-factor authentication (MFA)** combines two or more *distinct* factors. Two passwords are
still one factor. Under NIST SP 800-63B-4, a biometric only counts when paired with a physical
authenticator.

## Assurance Levels

NIST SP 800-63B-4 (August 2025, superseding SP 800-63B) defines three authenticator assurance
levels (AALs):

| Level | Confidence | Requires | Reauthentication |
| --- | --- | --- | --- |
| AAL1 | Basic | Single- or multi-factor; MFA options should be offered | Should be at most 30 days |
| AAL2 | High | Two distinct factors; verifiers must offer at least one phishing-resistant option | Should be at most 24 hours, or 1 hour idle |
| AAL3 | Very high | A phishing-resistant cryptographic authenticator with a non-exportable private key, plus an activation factor | Shall be at most 12 hours; should be 15 minutes idle |

## Passwords

SP 800-63B-4 overturns the composition rules many systems still enforce:

- **Length over complexity.** At least 15 characters when the password is the only factor, at
  least 8 when it is one factor of MFA; accept at least 64.
- **No composition rules.** Requiring mixed character classes is not permitted.
- **No periodic rotation.** Force a change only on evidence of compromise.
- **Blocklist instead.** Reject passwords found in breach corpuses, dictionaries, and
  context-specific words such as the service name.
- **Let password managers work.** Allow paste and autofill, and accept spaces and Unicode.

Store passwords only as salted hashes from a slow, memory-hard password hashing function; never
encrypt them reversibly.

## Phishing Resistance and Passkeys

One-time codes (SMS, email, TOTP) and push approvals are *not* phishing-resistant: a convincing
proxy site relays whatever the user types or approves. NIST classes SMS and voice codes as
*restricted* authenticators and does not allow email for out-of-band authentication at all.

Public-key authenticators built on **WebAuthn** (the browser API of the FIDO2 standards) resist
phishing structurally: the authenticator signs a challenge scoped to the website's origin, so a
look-alike domain receives a signature it cannot use. A **passkey** is such a credential:

- **Synced passkeys** are copied across a user's devices by a platform sync service. NIST permits
  syncable authenticators at AAL1 and AAL2.
- **Device-bound passkeys** (for example, on a hardware security key) never leave the device and
  are the only kind that can meet AAL3, which requires a non-exportable key.

> [!important] Phishing resistance is the property that matters
> Adding a second factor that can be relayed raises the cost of an attack but does not stop a
> real-time phishing proxy. Origin-bound public-key credentials do.

## Sessions and Tokens

Authentication happens once; the result is carried on every later request as a session cookie or
a token, so protecting that artefact matters as much as the login:

- **Browser sessions.** Issue a new session identifier at login (preventing session fixation),
  set cookies `Secure`, `HttpOnly`, and `SameSite`, and invalidate the session server-side at
  logout.
- **Tokens.** APIs usually carry a bearer token, often a
  [[concepts/identity_and_access/json_web_token|JSON Web Token (JWT)]]. Anyone holding a bearer
  token can use it, so keep lifetimes short and pair them with refresh tokens.
- **Reauthentication.** Enforce the overall and idle timeouts of the assurance level, and require
  a fresh login before sensitive actions such as changing the password or MFA settings.

## Machine and Workload Authentication

Services authenticate without a human present, so the factor is almost always a held secret or a
key. From weakest to strongest:

| Method | How it works | Trade-off |
| --- | --- | --- |
| Static API key or service-account key | A long-lived shared secret sent with each call | Simple; leaks are common and often never expire (see [[concepts/data_engineering/dbt/dbt_bigquery_adapter\|dbt-bigquery Adapter]]) |
| OAuth client credentials | The service exchanges a client secret or signed assertion for a short-lived access token | Tokens expire; the client secret still has to be stored |
| Mutual TLS (mTLS) | Both sides present X.509 certificates during the TLS handshake | Strong and transport-level; needs certificate issuance and rotation |
| Workload identity federation | The platform issues the workload a signed OIDC token, which a cloud provider exchanges for short-lived credentials | No stored secret at all; trust rests on the token's claims being pinned correctly |

[[concepts/data_engineering/dbt/deploy_dbt_cloud_run_github_actions|Deploy dbt and Elementary to Cloud Run with GitHub Actions]]
is a worked example of keyless federation from GitHub Actions to Google Cloud.

## Common Attacks

| Attack | What happens | Main defence |
| --- | --- | --- |
| Credential stuffing | Breached username–password pairs are replayed against another site | MFA, breached-password blocklists, rate limiting |
| Phishing and adversary-in-the-middle | A proxy site captures the password and relays the second factor | Phishing-resistant authenticators |
| MFA fatigue | Repeated push prompts until the user approves one | Number matching, rate limits, phishing-resistant methods |
| Account enumeration | Different responses reveal which usernames exist | Identical responses and timing for unknown and wrong-password cases |
| Session hijacking | A stolen cookie or token is replayed | Short lifetimes, secure cookie attributes, sender-constrained tokens |

## Related Concepts

- [[concepts/identity_and_access/authorization|Authorization]] — the step that consumes the identity authentication establishes
- [[concepts/identity_and_access/openid_connect|OpenID Connect (OIDC)]] — the standard way to federate authentication over OAuth 2.0
- [[concepts/identity_and_access/single_sign_on|Single Sign-On (SSO)]] — one authentication at an identity provider reused across many applications
- [[concepts/identity_and_access/oauth|OAuth (Open Authorization)]] — an authorization standard, often mistaken for authentication; OIDC layers authentication on top of it
- [[concepts/identity_and_access/json_web_token|JSON Web Token (JWT)]] — the token format that usually carries an authentication result
- [[concepts/data_governance/data_security|Data Security]] — authentication is the first control behind every access point it describes

## References

- [NIST SP 800-63B-4, Digital Identity Guidelines: Authentication and Authenticator Management](https://pages.nist.gov/800-63-4/sp800-63b.html)
- [W3C Web Authentication (WebAuthn)](https://www.w3.org/TR/webauthn/)
