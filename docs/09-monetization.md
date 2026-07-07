# Monetization

Status should be useful as a local native app first, then monetize around advanced integrations, automation, and optional cloud services.

## Monetization principle

Do not charge for complexity before the product earns trust.

Status should feel valuable before it asks for recurring payment.

## Possible models

### Option A: Paid app

One-time purchase for the native app.

Pros:

- simple;
- indie-friendly;
- no account required;
- matches native utility expectations;
- low operational burden.

Cons:

- hard to monetize ongoing plugin work;
- no recurring revenue for relay/cloud runner;
- cross-platform purchases may be awkward.

### Option B: Free app + paid Pro unlock

Free base app with paid Pro features.

Free:

- basic dashboard;
- bundled plugins;
- limited installed plugins;
- local-only operation;
- basic notifications.

Pro:

- unlimited plugins;
- advanced rules;
- more accounts;
- menu bar advanced status;
- custom webhooks;
- plugin developer mode;
- iCloud sync later;
- cloud relay later.

Pros:

- easy trial;
- lets product spread;
- supports recurring optional value.

Cons:

- needs careful limits;
- can feel SaaS-y if done badly.

### Option C: Local app paid once + cloud subscription

The app is paid once. Optional cloud features are recurring.

Paid app:

- local dashboard;
- local scheduler;
- local plugin store;
- notifications;
- rules.

Subscription:

- webhook relay;
- push notifications;
- always-on cloud runner;
- cross-device sync;
- server-side scheduled checks;
- team sharing later.

Pros:

- clean value boundary;
- local-first preserved;
- cloud costs funded.

Cons:

- two-part pricing;
- more messaging complexity.

## Recommended model

Start with:

```txt
Free local beta
→ paid Pro unlock
→ optional cloud subscription later
```

Suggested v1 pricing experiments:

```txt
Free
- built-in plugins
- 2 installed plugins
- 3 accounts
- basic notifications
- local-only

Pro
- unlimited plugins
- unlimited accounts
- advanced rules
- custom webhooks
- plugin developer mode
- menu bar advanced controls
- one-time or yearly price

Cloud, later
- webhook relay
- push notifications
- always-on runner
- server-side checks
```

## Product tiers

### Free

For testing and casual use.

Limits:

- bundled plugins;
- small number of installed plugins;
- limited rules;
- local-only;
- no cloud relay.

### Pro

For indie builders and power users.

Includes:

- unlimited local integrations;
- advanced automation rules;
- plugin developer mode;
- custom webhook plugin;
- menu bar status;
- local audit history;
- export/import;
- optional iCloud config sync later.

### Cloud

Optional add-on.

Includes:

- webhook relay;
- iOS push notifications;
- always-on scheduled checks;
- server-side rule execution;
- remote action runner;
- encrypted token storage;
- longer event retention.

## Pricing direction

Possible pricing:

```txt
Status Pro
€29-€49 one-time
or
€3-€5/month
or
€29-€39/year

Status Cloud
€5-€9/month
```

Do not decide final pricing before validating real usage.

## What not to monetize early

Avoid charging separately for every plugin in v1.

This would make the plugin store feel hostile. Better to charge for capacity or Pro features.

Avoid:

- per-plugin microtransactions;
- per-notification pricing;
- confusing credit systems;
- locking basic App Store/GitHub/Jira plugins behind separate purchases before the product is trusted.

## Plugin marketplace monetization later

Later, third-party plugin marketplace could support:

- verified plugin badge;
- paid plugins;
- revenue share;
- plugin developer accounts;
- private plugin distribution.

This should not be part of v1.

## Business positioning

Status is for:

- indie app developers;
- solo founders;
- small product studios;
- content creators with multiple channels;
- developer-designers;
- consultants juggling many tools;
- people running many small products.

Possible tagline:

```txt
One native status layer for everything you run.
```

## Why people would pay

People pay because Status saves:

- dashboard switching;
- missed review states;
- missed failed deploys;
- missed channel drops;
- context switching;
- repetitive follow-up work.

The value is not raw data. The value is attention saved.

## Launch strategy

Start with a narrow audience:

```txt
Indie Apple developers with multiple apps.
```

First strong use case:

```txt
See all App Store Connect statuses without opening App Store Connect.
```

Then expand:

```txt
Add GitHub/Jira/YouTube/Cloudflare into the same attention layer.
```

## Metrics to watch

Useful product metrics:

- connected accounts per user;
- installed plugins per user;
- weekly opens;
- notifications clicked;
- rules created;
- actions run;
- plugin sync failures;
- time to first useful status;
- number of source dashboards replaced.

Avoid vanity metrics such as total raw events without engagement context.

## Monetization doctrine

```txt
Local app value first.
Cloud value second.
Marketplace value last.
```