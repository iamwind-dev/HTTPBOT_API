# NTLM Auth — Design

Date: 2026-06-09
Branch: `feat/auth_NTLM`

## Goal

Add working **NTLMv2 authentication** to the Request editor for all HTTP methods
(GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS).

When the user selects `Auth = NTLM`, enters a username/password (domain optional),
and presses Send, the app performs a real NTLM challenge/response handshake with
the server. NTLM is **not** faked with Basic auth, and **no** `Authorization`
header is written into the Headers UI.

## Context — current state

The codebase already declares NTLM but does not implement it:

- `AuthType.ntlm` exists in `request_auth_draft.dart`.
- `NtlmAuthDraft { username, password, domain, workstation }` exists, but has **no**
  `copyWith` and **no** validation getter.
- `ApplyRequestAuthUseCase` returns an `unsupportedAuthType` auth issue for `ntlm`.
- `_AuthSection` in `request_editor_sheet.dart` falls through to a generic
  "not supported yet" info card for `ntlm`.
- The network layer is **Dio over `dart:io` HttpClient** (`DioClient.create`).
  There is no `http` package and no NTLM package. `dart:io` has no built-in NTLM.

Other auth types (Basic, Bearer, JWT, AWS, API Key, OAuth2) work by **stripping**
the auth from the request and **syncing** a generated header/query param into the
Headers/Query UI before send. NTLM cannot work this way — it authenticates the
TCP connection via a multi-message handshake.

## Decisions

- **Implementation strategy:** self-contained NTLMv2 handshake, no new packages.
- **Scope:** full pipeline (UI + state + validation + routing + handshake + response
  mapping) plus unit tests. Real-server verification is out of scope (no NTLM
  test server available).
- **Routing:** `ApplyRequestAuthUseCase` carries NTLM requests through with auth
  intact; `RequestExecutionRepositoryImpl` branches on `appliedAuthType == ntlm`
  and delegates to `NtlmHttpClient`. Minimal blast radius — all other auth
  unchanged.
- **Persistence:** NTLM username/password/domain persist in the request draft
  exactly like Basic/AWS credentials already do (existing autosave). No special
  redaction.

## 1. Domain — entity & validation

### `NtlmAuthDraft` (extend existing)

Add:

- `copyWith({String? username, String? password, String? domain, String? workstation})`
  — currently missing; the UI needs it to follow the AWS/Basic field pattern.
- `bool get canApplyNtlm => username.trim().isNotEmpty && password.isNotEmpty;`
  There is no per-auth `enabled` flag in this draft model (auth on/off is
  `type == AuthType.none`), so `canApplyNtlm` does not reference `enabled`.

### `ApplyRequestAuthUseCase`

- Remove `AuthType.ntlm` from the `unsupportedAuthType` branch.
- Add `_applyNtlmAuth()`:
  - Validate username → missing yields a `RequestAuthIssue`
    (`missingCredentials`, fieldName `username`, "Username is required for NTLM.").
  - Validate password → missing yields a `RequestAuthIssue`
    (`missingCredentials`, fieldName `password`, "Password is required for NTLM.").
  - Domain is optional (no validation).
  - On success: return the request with **auth preserved** (not reset to
    `RequestAuthDraft.none()`) and **no header sync**. This is the single place
    NTLM deviates from every other auth type.

Result: `AuthAppliedRequest.appliedAuthType == AuthType.ntlm` and the draft still
carries credentials into the repo.

## 2. Network layer — `NtlmHttpClient`

New: `lib/core/network/ntlm_http_client.dart` and a `lib/core/network/ntlm/`
folder of pure-Dart, independently testable helpers:

- `ntlm_type1_message.dart` — build the Type-1 (negotiate) message.
- `ntlm_type2_message.dart` — parse the Type-2 (server challenge) message.
- `ntlm_type3_message.dart` — build the Type-3 (authenticate) message using the
  NTLMv2 response (HMAC-MD5 via the existing `crypto` package).
- message encoding/decoding helpers (base64, little-endian fields, target info).

The client:

- Drives Dio with `IOHttpClientAdapter` and a **single persisted `HttpClient`**
  (NTLM authenticates the connection, so keep-alive across the handshake matters).
- Flow: send Type-1 → read `WWW-Authenticate: NTLM <challenge>` → resend with the
  Type-3 header **plus** the real method, headers, body.
- Honors timeout, `verifySsl`, URL + query params, user headers, body, and
  auto-content-type — reusing the **same** builders the repo already uses
  (shared bits extracted so the two paths cannot diverge).
- Maps the final response into the same `RequestExecutionResult` shape as the
  default path.

Error mapping:

- 401 → "NTLM authentication failed. Check username, password, and domain."
- No `WWW-Authenticate: NTLM` offered by server → "Server did not request NTLM
  authentication."
- Network failure → "Network request failed." (mapped to existing error types)
- Web / unsupported platform → "NTLM authentication is not implemented for this
  platform yet."

No logging of password or NTLM challenge/response tokens.

## 3. Routing in the execution repo

`RequestExecutionRepositoryImpl.executeRequest`:

- If `request.appliedAuthType == AuthType.ntlm` → delegate to `NtlmHttpClient`.
- Otherwise → existing Dio path, unchanged.

`NtlmHttpClient` is registered in `get_it` and injected into the repo constructor
(like `DioClient`). Shared request-building (execution URL, header map, body
payload) is extracted into a helper both paths call — no double-send, no drift.

## 4. UI — `_AuthSection`

- Replace the `ntlm` fallthrough with `AuthType.ntlm => _NtlmAuthFields(ntlm: auth.ntlm)`.
- New `_NtlmAuthFields` widget, mirroring `_AwsAuthFields`:
  - **Username** — text field; not trimmed while typing (trim only at send).
  - **Password** — text field, `obscureText: true`.
  - **Domain** — text field, optional.
- No workstation field in the UI (stays in the model, defaults empty).
- `_GeneratedAuthFieldsCard` gets an `AuthType.ntlm` branch:
  "NTLM authenticates the connection during send; no Authorization header is
  added here." — correctly signalling nothing is synced into Headers.

## 5. Tests

- `test/features/request_builder/domain/auth/ntlm_auth_entity_test.dart`
  - canApplyNtlm true with username+password.
  - false when username empty.
  - false when password empty.
  - true with empty domain (username+password present).
- `test/features/request_builder/data/datasources/ntlm_request_routing_test.dart`
  - NTLM auth routes to `NtlmHttpClient`.
  - Other auth types do not route to `NtlmHttpClient`.
  - NTLM does not add an `Authorization` row to Headers.
  - Content-Type preserved when Auth = NTLM.
  - User headers preserved when Auth = NTLM.
- `test/features/request_builder/presentation/auth/ntlm_auth_ui_test.dart`
  - Selecting NTLM renders Username/Password/Domain.
  - Send with empty username → validation error.
  - Send with empty password → validation error.
- NTLM message encoding unit tests against known Type-2/Type-3 vectors.

No real-server integration test (no NTLM server available) — noted as follow-up.

## Out of scope

- Real-server verification and manual NTLM-server testing.
- NTLM over HTTP proxies.
- NTLM on web (throws the unsupported-platform message).
