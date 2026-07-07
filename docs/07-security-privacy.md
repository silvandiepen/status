# Security and Privacy

Status handles accounts, tokens, API keys, events, operational data, and possible automation actions. Security is part of the product, not a later feature.

## Security posture

Default posture:

```txt
Local-first.
Read-only-first.
Explicit permissions.
No hidden code execution.
No plugin-owned UI.
Audit every action.
```

## Secret storage

Secrets must be stored in Keychain.

Examples of secrets:

- OAuth access token;
- OAuth refresh token;
- API key;
- private key;
- webhook secret;
- bearer token;
- basic auth password.

Never store these in:

- plugin files;
- SQLite plaintext;
- logs;
- crash reports;
- analytics payloads;
- exported config.

SQLite may store references to Keychain entries.

## Plugin package verification

Before installing a plugin, Status should verify:

- package hash;
- package signature;
- plugin ID;
- version;
- minimum core version;
- supported platforms;
- revocation/blocklist status;
- requested permissions;
- declared domains.

Unsigned local plugins should require Developer Mode and clear warnings.

## Network boundary

Plugins must declare allowed domains.

The request engine must reject any URL outside declared domains.

Example:

```json
{
  "domains": ["api.github.com"]
}
```

If a mapping or request tries to send data to another host, it should fail closed.

## Permission model

Permissions should be granular.

Suggested permission groups:

```txt
Network access
Account authentication
Keychain secret storage
Background refresh
Incoming webhook
Read resources
Read metrics
Create external item
Send external message
Modify external resource
```

Write permissions should not be granted simply because a plugin is installed. They should be requested when a rule/action requires them.

## Action safety

Action safety levels:

```txt
safe
review-required
dangerous
unsupported
```

### Safe actions

Examples:

- local notification;
- add to inbox;
- open URL;
- local audit note.

### Review-required actions

Examples:

- create Jira issue;
- create GitHub issue;
- send webhook;
- create email draft.

### Dangerous actions

Avoid in v1.

Examples:

- delete remote data;
- modify App Store metadata;
- submit app builds;
- send email automatically;
- change billing settings;
- transition production state.

## Audit log

Every external action should create an audit entry.

Audit should include:

- rule name;
- event that triggered it;
- action type;
- target account/resource;
- input summary;
- result;
- timestamp;
- source link;
- error if failed.

The audit log is part of user trust.

## Push/webhook security

Incoming pushes should use one of:

- provider signature verification;
- HMAC shared secret;
- bearer token;
- signed payload;
- secret URL token, only for low-risk generic webhooks.

The relay should validate signatures before forwarding payloads where possible.

## Cloud relay privacy

If Status Relay is introduced, it should start minimal.

Relay should:

- receive webhook payloads;
- verify signatures;
- store events briefly;
- forward to devices;
- avoid long-term storage by default;
- avoid executing rules in v1;
- make retention clear.

Relay should not become a hidden backend dependency for local-first users.

## Telemetry

Telemetry should be minimal and opt-in if possible.

Useful product telemetry, if added:

- app version;
- plugin install count;
- plugin sync success/failure counts;
- crash/error categories.

Avoid collecting:

- event payloads;
- resource names;
- API responses;
- user account identifiers;
- secrets;
- rule contents;
- operational data from connected services.

## Export/import

Config export should exclude secrets by default.

Export may include:

- installed plugin IDs;
- rule definitions;
- dashboard layout;
- non-secret account display names;
- local preferences.

Export must not include:

- tokens;
- private keys;
- API keys;
- webhook secrets.

## Threat model

Important risks:

- malicious plugin package;
- tampered plugin registry;
- token exfiltration;
- noisy or harmful automations;
- accidental external write action;
- webhook spoofing;
- overbroad plugin permissions;
- logs leaking operational data.

Mitigations:

- plugin signatures;
- declared domains;
- Keychain-only secrets;
- user-visible permissions;
- read-only-first integrations;
- action safety levels;
- audit log;
- revocation/blocklist;
- limited relay storage;
- no arbitrary plugin code in v1.

## Guiding principle

```txt
Trust is the product moat.
```