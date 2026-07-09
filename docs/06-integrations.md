# Official Plugins and App Ideas

Status should start with a small set of useful official plugins, then grow through installable registry plugins. A plugin is the available package. An app is a configured instance created from a plugin. One plugin can support many apps with different names, accounts, credentials, rules, notifications, dashboard tiles, and detail settings.

## Official plugin boundaries

An official Status plugin should make a provider easier to monitor, not replace the provider's full product. The plugin should answer what changed, what is stuck, what needs attention, and where to act next. It should expose direct links back to the provider for deep work.

Official plugins must have:

- stable icon and accent color used everywhere the plugin/app appears;
- setup flow and provider-specific setup documentation;
- permissions and declared domains;
- support for multiple configured apps/accounts when the provider allows it;
- editable local display name per configured app;
- dashboard tile options;
- app detail views;
- resource list or equivalent detail surface;
- event declarations and notification defaults;
- app-scoped rule presets, disabled by default;
- direct source links;
- error handling;
- audit output for actions;
- fixture data and schema validation;
- documentation renderable on the Status website.

Official plugins should avoid:

- pretending to be the provider's full dashboard;
- high-risk write actions in v1;
- noisy notification defaults;
- provider-specific custom UI code;
- hidden OAuth or credential behavior;
- data collection beyond declared setup and permissions.

## Plugin categories

### Developer operations

- App Store Connect
- GitHub
- GitLab
- Jira
- Cloudflare
- Sentry
- Vercel
- Netlify
- Supabase
- Hetzner

### Content and channels

- YouTube
- RSS/feed
- Plausible/Fathom
- Google Analytics, later

### Business

- Stripe
- Paddle, later
- Lemon Squeezy, later

### Communication

- Gmail, later
- Slack
- Discord
- Email draft action

### Local/basic

- website uptime
- network check
- manual status
- generic webhook
- weather

## Bundled plugins

Bundled plugins should be universal and low-risk.

Recommended bundled set:

```txt
Website uptime
Network check
Manual status
RSS/feed
Generic webhook
Weather, optional
```

These make the app useful before a user installs anything.

## Registry plugins

Installable plugins should be optional and served through the Cloudflare registry API, with immutable packages in R2 and metadata on the website.

Recommended first store plugins:

```txt
App Store Connect
GitHub
GitLab
Jira
YouTube
Cloudflare
Stripe
Sentry
Plausible/Fathom
```

## App Store Connect plugin

Purpose:

- show app list;
- show app review status;
- show latest version/build state;
- show waiting/in review/rejected/ready states;
- link directly to App Store Connect;
- emit events for review state changes.

Resources:

```txt
app
version
build
review_submission
review_message, later
```

Events:

```txt
app.review.rejected
app.review.in_review
app.review.waiting_for_review
app.version.ready_for_sale
app.build.processing_failed
```

Current implementation note: the bundled App Store Connect package uses `jwt-api-key` auth (`issuerId`, `keyId`, `.p8` private key) and asks for one `appId` during native setup. Manual refresh can list apps with JSON:API pagination; the scheduled review-state check uses the configured `appId` directly until the runtime supports chained per-resource requests.

Required documentation:

- where to find or create the issuer ID;
- where to create an API key and retrieve the key ID;
- how to download and store the `.p8` private key;
- where to find the App Store Connect app ID;
- required App Store Connect API access;
- least-privilege setup guidance;
- limitations: Status reads review/build/app status and opens App Store Connect links; it does not submit builds, edit metadata, or reply to review.

Views:

- overview cards;
- app list;
- app detail;
- review timeline;
- needs attention panel.

Actions v1:

- open original;
- create local note;
- create Jira/GitHub issue through other plugins.

Avoid:

- submitting builds;
- editing metadata;
- replying automatically.

## GitHub plugin

Purpose:

- show repositories;
- show PRs needing review;
- show failing workflows;
- show recent issues;
- show blocked work;
- receive webhook events later.

Resources:

```txt
repository
pull_request
issue
workflow_run
release
```

Events:

```txt
github.pr.review_requested
github.pr.merged
github.workflow.failed
github.issue.assigned
github.release.published
```

Actions:

```txt
github.createIssue
github.commentOnIssue
github.openUrl
```

Avoid v1:

- merging PRs;
- closing issues;
- modifying branches.

## GitLab plugin

Purpose:

- show tracked projects;
- show failed pipelines;
- show recent merge request and issue activity;
- link directly to GitLab project, pipeline, merge request, and issue pages;
- support multiple configured apps for different projects or accounts.

Resources:

```txt
project
pipeline
merge_request
issue
release, later
```

Events:

```txt
gitlab.pipeline.failed
gitlab.merge_request.opened
gitlab.issue.opened
gitlab.release.published, later
```

Current implementation note: the bundled GitLab package uses `api-key` header auth with `PRIVATE-TOKEN`, asks for one project ID or URL-encoded project path, reads project details, polls pipelines, and can manually refresh project activity. It is read-only and stores the token in Keychain through the shared plugin setup flow.

Actions:

```txt
gitlab.openUrl
gitlab.createIssue, later
gitlab.addComment, later
```

Avoid v1:

- merging merge requests;
- closing issues;
- modifying branches;
- changing pipeline variables or project settings.

## Jira plugin

Purpose:

- show assigned issues;
- show recently updated issues;
- show blocked issues;
- show project status;
- create follow-up issues from events.

Resources:

```txt
site
project
board
issue
sprint
```

Events:

```txt
jira.issue.assigned
jira.issue.updated
jira.issue.blocked
jira.issue.moved_to_review
jira.issue.overdue
```

Actions:

```txt
jira.createIssue
jira.addComment
```

Avoid v1:

- transitions;
- bulk edits;
- deleting issues.

## YouTube plugin

Purpose:

- connect multiple Google accounts/channels;
- show channels without switching accounts;
- show basic channel metrics;
- show latest uploads;
- warn about unusual drops.
- link to relevant YouTube Studio pages for deeper creator work.

Boundary:

- Status is a creator status surface, not a YouTube Studio replacement;
- show the most important channel/profile state, latest published content, key metrics, and attention items;
- do not upload videos, change metadata, manage comments, or replace analytics exploration.

Resources:

```txt
channel
video
metric_period
```

Events:

```txt
youtube.channel.views_dropped
youtube.channel.subscribers_changed
youtube.video.published
youtube.channel.no_upload_recently
```

Metrics:

```txt
views_7d
views_28d
subscribers_28d
watch_time_28d
latest_upload_age
```

Actions v1:

- open YouTube Studio;
- add to Status inbox;
- notify.

Avoid:

- uploading videos;
- changing metadata;
- posting comments.

## Cloudflare plugin

Purpose:

- show domains;
- show Workers;
- show Pages deployments;
- show R2 buckets;
- show failed deployments;
- show DNS/SSL attention items.

Resources:

```txt
account
zone
worker
pages_project
deployment
r2_bucket
```

Events:

```txt
cloudflare.deployment.failed
cloudflare.zone.ssl_issue
cloudflare.worker.error_rate_high
cloudflare.domain_expiring
```

Actions:

- open dashboard link;
- send notification;
- create issue via GitHub/Jira.

Avoid v1:

- editing DNS;
- deploying workers;
- deleting resources.

## Website uptime plugin

Purpose:

- monitor URLs;
- show current availability;
- emit events when down/recovered;
- record response time.

Resources:

```txt
website
endpoint
```

Events:

```txt
website.down
website.recovered
website.slow
```

Actions:

- notification;
- webhook;
- create issue through another plugin.

## Generic webhook plugin

Purpose:

- let any script/service emit events into Status;
- support custom payloads;
- support secret/token verification;
- bridge unsupported services.

### Local model before the relay

Until the relay exists (roadmap Phase 10), a local-only Mac has no public URL, so "generic webhook" in v1 means:

- a local HTTP listener on localhost, off by default and opt-in, for scripts and tools running on the same machine or LAN;
- manual payload import (paste or file) for testing mappings and rules.

Payloads still require the shared-secret/token check. True public inbound webhooks arrive with the relay and reuse the same payload shape, so nothing built against the local model changes later.

Event shape:

```json
{
  "type": "deploy.failed",
  "resource": "example.com",
  "title": "Deploy failed",
  "summary": "Production deployment failed.",
  "severity": "critical",
  "url": "https://github.com/..."
}
```

## Weather plugin

Weather is useful as a bundled example because it is generic and low-risk. It should not dominate the product.

Purpose:

- show current local weather;
- show severe weather notices if available;
- support simple status cards.

Avoid turning Status into a weather app.

## Additional official plugin candidates

Developer operations:

- Vercel: deployments, failed builds, project links, domain issues.
- Netlify: deployments, form submissions, build failures, domain/SSL attention.
- Supabase: project health, database/storage usage, edge function errors.
- Sentry: new issues, regressions, release health, assigned issues.
- Hetzner: server status, resource usage, invoices/limits where read-only APIs allow.
- Docker Hub/GitHub Container Registry: image publish status and failed builds where available.

Creator and publishing:

- RSS/feed: recent posts and feed errors.
- Plausible/Fathom: traffic changes, top pages, uptime-adjacent marketing signals.
- Mastodon/Bluesky/LinkedIn, later: post/account status only if API access is stable and low-risk.

Business:

- Stripe: payment failures, disputes, MRR/volume summary, payouts.
- Paddle: payments, subscriptions, payouts, disputes.
- Lemon Squeezy: orders, subscriptions, license events.

Communication:

- Gmail/Email: unread/action-required summaries and email draft actions only.
- Slack: mentions, channel alerts, workflow events; no automatic posting in v1.
- Discord: server/channel alerts and webhook-based events.

Local/basic:

- Manual status: user-entered status tile and events.
- Network check: local connectivity and DNS checks.
- Weather: severe weather notices and current local state only.

## Plugin priority

Recommended order:

1. Website uptime.
2. Generic webhook.
3. App Store Connect.
4. GitHub.
5. GitLab.
6. Jira.
7. YouTube.
8. Cloudflare.
9. Stripe.
10. Sentry.
11. Plausible/Fathom.

## Plugin acceptance criteria

Each official plugin should have:

- a stable icon and color used everywhere the plugin or configured app appears;
- setup flow and setup documentation;
- permissions screen;
- support for multiple configured apps/accounts/resources when the provider allows it;
- editable local display name per configured app;
- app dashboard tile configuration;
- app detail page configuration;
- resource list;
- at least one event type;
- at least one useful status item;
- app-scoped notification defaults;
- app-scoped suggested rules disabled by default;
- direct source links;
- error handling;
- audit output for actions;
- docs, fixtures, and example plugin manifest.

## Plugin philosophy

A plugin is successful when each configured app saves a dashboard visit.

If a plugin only mirrors data without deciding what matters, it is not finished.
