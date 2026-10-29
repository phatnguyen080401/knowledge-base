---
title: JSON Web Token (JWT)
tags: [identity-and-access, access-management, jwt]
sources: ["https://www.rfc-editor.org/rfc/rfc8725.html"]
created: 2026-10-29 14:09:46
updated: 2026-10-29 14:09:46
---

# JSON Web Token (JWT)

A JSON Web Token (RFC 7519) is a compact, URL-safe way to carry a set of claims, such as who a user
is and when the token expires, protected by a signature (JWS) or encryption (JWE). It is the format
of [[concepts/identity_and_access/openid_connect|OpenID Connect (OIDC)]] ID tokens and of many
[[concepts/identity_and_access/oauth|OAuth (Open Authorization)]] access tokens.

## Why It Matters

- **Verification without a lookup.** A service holding the issuer's public key can check a token
  locally, with no call to the issuer, which is why JWTs suit distributed systems.
- **Its flexibility is its risk.** The header tells the verifier which algorithm to use, and a
  library that trusts that header can be tricked; RFC 8725 exists because of real attacks.
- **Signed is not secret.** Most JWTs are signed, not encrypted, and anyone holding one can read
  every claim.

## Structure

A signed JWT is three base64url-encoded parts joined by dots: `header.payload.signature`.
Decoded, the first two are JSON:

```json
{ "alg": "RS256", "typ": "JWT", "kid": "2026-10-key-1" }
```

```json
{
  "iss": "https://login.example.com",
  "sub": "248289761001",
  "aud": "orders-api",
  "exp": 1793260186,
  "iat": 1793256586
}
```

The signature covers the encoded header and payload, so changing any claim invalidates it.

| Registered claim | Meaning |
| --- | --- |
| `iss` | Issuer |
| `sub` | Subject the claims are about |
| `aud` | Intended recipients |
| `exp` | Expiry; reject after this time |
| `nbf` | Not before; reject before this time |
| `iat` | Issued at |
| `jti` | Unique token ID, usable for replay detection or revocation lists |

## Signing and Encryption

| Family | Algorithms | Key model | Use when |
| --- | --- | --- | --- |
| HMAC | `HS256` | One shared secret signs and verifies | Issuer and verifier are the same service |
| RSA | `RS256`, `PS256` | Private key signs, public key verifies | Many verifiers, one issuer |
| Elliptic curve | `ES256`, `EdDSA` | As RSA, with smaller keys and signatures | As RSA |
| Encryption (JWE) | e.g. `RSA-OAEP` with `A256GCM` | Recipient's public key encrypts | The claims themselves are confidential |

Issuers publish public keys as a JSON Web Key Set (JWKS); the `kid` header says which key signed
the token, which makes rotation possible without downtime.

## Validation Checklist

RFC 8725 (JWT Best Current Practices, February 2020) reduces to:

1. **Pin the algorithm.** Configure which algorithms are accepted, and use each key with exactly
   one algorithm; never let the token's `alg` header choose.
2. **Reject `none`** and any token where any cryptographic step fails, including the inner layer
   of a nested token.
3. **Use strong keys.** Never a human-memorable password as an HMAC secret.
4. **Check `iss`** and that the signing key belongs to that issuer, and that `sub` is valid for
   the application.
5. **Check `aud`** and reject tokens issued for another recipient.
6. **Check time claims** (`exp`, `nbf`) with a small clock-skew allowance.
7. **Type the token** with an explicit `typ`, and make validation rules for different token kinds
   mutually exclusive so one kind cannot be passed off as another.
8. **Treat claims as untrusted input** when they feed database queries or URLs.

## Attacks

| Attack | How it works | Defence |
| --- | --- | --- |
| `alg: none` | The attacker strips the signature and sets the algorithm to none | Algorithm allow-list |
| Algorithm confusion | An `RS256` token is relabelled `HS256` and verified with the RSA *public* key as the HMAC secret | One algorithm per key; allow-list |
| Weak HMAC key | A captured token is brute-forced offline | High-entropy keys |
| Substitution | A token issued to one service is replayed to another | Audience validation |
| Cross-JWT confusion | A token of one kind, such as an ID token, is accepted as another, such as an access token | Explicit typing, mutually exclusive rules |
| Indirect attacks | A claim used in a query or URL enables injection or SSRF | Validate claims like any input |

## Stateless Tokens and Revocation

A JWT stays valid until it expires, because verifiers do not ask the issuer. The usual answer is
short-lived access tokens paired with revocable refresh tokens; when immediate revocation matters,
an opaque token checked through introspection, or a deny-list keyed on `jti`, trades back some of
the statelessness.

> [!warning] Decoding is not verifying
> Base64-decoding a JWT and reading its claims checks nothing. Only a library call that verifies
> the signature, algorithm, issuer, audience, and expiry makes the claims trustworthy.

## Related Concepts

- [[concepts/identity_and_access/openid_connect|OpenID Connect (OIDC)]] — every ID token is a JWT with a defined claim set and validation procedure
- [[concepts/identity_and_access/oauth|OAuth (Open Authorization)]] — access tokens are often JWTs, as profiled in RFC 9068
- [[concepts/identity_and_access/authorization|Authorization]] — tampered or unverified claims are a listed broken-access-control pattern
- [[concepts/identity_and_access/authentication|Authentication]] — JWTs usually carry the result of an authentication to later requests

## References

- [RFC 8725, JSON Web Token Best Current Practices](https://www.rfc-editor.org/rfc/rfc8725.html)
- [RFC 7519, JSON Web Token (JWT)](https://www.rfc-editor.org/rfc/rfc7519.html)
