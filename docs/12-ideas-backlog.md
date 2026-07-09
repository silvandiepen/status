# Ideas Backlog

This document collects ideas that are not yet committed requirements.

Use this as a holding area. Good ideas should later move into `SPEC.md`, `docs/02-requirements.md`, or implementation issues.

## Product ideas

### Menu bar mode

A compact always-visible status indicator.

Possible states:

```txt
All good
3 notices
1 critical
Sync failed
Offline
```

Click opens the main app or a compact popover.

### Attention inbox

A unified inbox of unresolved status items.

Items can be:

- dismissed;
- snoozed;
- marked resolved;
- linked to source;
- converted into issue/task;
- added to digest.

### Daily digest

A daily summary:

```txt
Since yesterday:
- 2 apps changed state
- 1 YouTube channel dropped below baseline
- 3 Jira issues updated
- 1 website had downtime
- 2 automations ran
```

### Product groups

Group resources by product instead of provider.

Example:

```txt
Tiko
- App Store app
- GitHub repo
- Cloudflare site
- Jira project
- YouTube channel, if any

Mazzi
- Multiple apps
- Website
- GitHub repo
```

This may be more useful than provider-first navigation.

### Status pages for personal products

Generate a private or public status page from selected resources.

This should not be part of v1.

### Local Markdown report export

Export status digest to Markdown.

Useful for:

- weekly reviews;
- investor/advisor updates;
- product notes;
- GitHub issues;
- personal logs.

### Command palette

Quick actions:

```txt
Refresh all
Open Tiko Yes No in App Store Connect
Show critical items
Install plugin
Run rule
Open audit log
```

### Status score

A simple derived score per product or integration.

Avoid making this gimmicky. It may be useful only if explainable.

### Product memory

For each product, store:

- description;
- domain;
- repo;
- app IDs;
- channels;
- current status;
- notes;
- launch checklist;
- pricing;
- support links.

This could connect Status to a broader product operating system later.

## Plugin ideas

### App Store Connect

High priority.

Primary use:

- review state;
- app versions;
- build status;
- links;
- rejection attention.

### GitHub

High priority.

Primary use:

- PRs needing review;
- failing workflows;
- assigned issues;
- releases;
- repo status.

### Jira

High priority if used for work.

Primary use:

- assigned issues;
- recently updated issues;
- blocked issues;
- create issue from external event.

### YouTube

High priority for multiple channels.

Primary use:

- list all channels without switching;
- latest upload;
- 7/28-day metrics;
- drop detection.

### Cloudflare

Medium-high priority.

Primary use:

- domains;
- Worker deploy failures;
- Pages deployments;
- R2 buckets;
- DNS/SSL issues.

### Generic webhook

High priority because it unlocks unsupported tools.

Primary use:

- receive custom events;
- create events from scripts;
- deployment notifications;
- small product alerts.

### Website uptime

High priority bundled plugin.

Primary use:

- check URL health;
- emit down/recovered events;
- simple response time metric.

### RSS/feed

Useful bundled plugin.

Primary use:

- monitor provider changelogs;
- app review/news feeds;
- GitHub releases if no API;
- product mentions.

### Stripe

Later.

Primary use:

- failed payments;
- unusual revenue changes;
- disputes;
- payouts;
- MRR if relevant.

### Sentry

Later.

Primary use:

- new issue;
- issue regression;
- high error rate;
- release health.

### Plausible/Fathom

Later.

Primary use:

- site traffic changes;
- unusual spikes/drops;
- top referrers;
- product pages.

## Automation ideas

### App rejected → issue

```txt
When App Store app is rejected
→ notify
→ create Jira/GitHub issue
→ include review message and source link
```

### Workflow failed → issue

```txt
When GitHub workflow fails on main
→ notify
→ create issue if not already open
```

### Website down → escalation

```txt
When website is down for 2 checks
→ notify
→ create issue
→ send webhook
```

### YouTube drop → review

```txt
When views drop more than 20%
→ add to attention inbox
→ notify only in digest
```

### No upload → reminder

```txt
When channel has no upload for X days
→ show reminder
```

### Jira moved to QA → notify

```txt
When issue assigned to me moves to QA
→ notify
→ open issue link
```

### Cloudflare deploy failed → GitHub issue

```txt
When Pages/Worker deployment fails
→ notify
→ create issue in linked repo
```

## UI ideas

### Provider-first sidebar

```txt
Overview
App Store
YouTube
Jira
GitHub
Cloudflare
Settings
```

Simple and obvious.

### Product-first dashboard

```txt
Tiko
Mazzi
Lezin
Pietru
Luys
```

Potentially more useful later.

### Split layout on macOS

```txt
Sidebar
→ main list/cards
→ right detail panel
```

### Compact iOS flow

```txt
Overview tab
Alerts tab
Plugins tab
Settings tab
```

### Needs Attention panel

Always show a prioritized list of items requiring action.

Sort by:

1. critical unresolved;
2. warning unresolved;
3. recently changed;
4. stale/stuck;
5. notices.

## Technical ideas

### Declarative mapping language

Need a small expression/mapping system.

Possible features:

- JSONPath-like selectors;
- template strings;
- simple comparisons;
- severity mapping;
- conditional event emit;
- pagination definitions.

Avoid full scripting in v1.

### Plugin schema validator

Provide a CLI or internal dev screen to validate plugin packages.

### Local sample plugins

Keep sample plugins in the repo later:

```txt
plugins/examples/uptime
plugins/examples/rss
plugins/examples/generic-webhook
plugins/examples/mock-app-store
```

### Replay events

Developer tool to replay stored events through the rules engine.

Useful for testing automations.

### Rule dry-run

Show how often a rule would have triggered in recent history.

### Plugin compatibility tests

Test plugin package against current core schema.

## Cloud ideas

### Relay only

Small service that receives webhooks and delivers them to devices.

### Cloud runner

Optional service that runs scheduled jobs/rules when user devices are offline.

### Shared product map

Cloud sync of product/resource grouping, but not necessary for v1.

## Ideas to reject for now

- full enterprise team dashboard;
- arbitrary plugin code execution;
- custom plugin UI framework;
- generic low-code workflow builder;
- App Store metadata editor;
- social posting automation;
- email auto-send;
- destructive actions;
- replacing Jira/GitHub/App Store Connect;
- cloud-first account requirement.

## Backlog doctrine

```txt
Keep ideas here until they are proven useful enough to become requirements.
```
