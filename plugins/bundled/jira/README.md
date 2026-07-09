# Jira

Read Jira project issue status and create controlled follow-up issues from Status rules.

## Why install this plugin

Install Jira when Status should show the important work state of a project and route follow-up from other apps into Jira. It is not a replacement for Jira boards or backlog planning; it is a compact operational view and a controlled action target.

## What you configure

Create one configured app per Jira project:

- **Atlassian site** — your Jira Cloud hostname, for example `example.atlassian.net`
- **Project key** — the Jira project key, for example `STATUS`
- **Atlassian email** — the email for the Atlassian account
- **API token** — an Atlassian API token for that account

## What it exposes

### Resources

- **jira_issue** — recent issues in the configured project

### Events

| Event | Meaning | Default notification |
| --- | --- | --- |
| `jira.issue.open` | A recent issue is still in a non-done status category | Dashboard only |

### Views

- **Jira issues** — recent issues with status, priority, assignee, and summary
- **Recent Jira issue activity** — issue status and update activity

### Checks

- **Check Jira issues** — cron schedule every 30 minutes
- **Refresh Jira issues** — manual check on demand

## Suggested automations

Suggested rules ship disabled. Enable presets per configured app if you want open issue events added to the Status inbox.

## Actions

- **Create Jira issue** — controlled `jira.createIssue` action that creates a Task in the configured project after an explicit Status rule/action review and `write-actions` permission grant.

## Permissions and domains

- `network` — read and write Jira REST API data
- `keychain` — store the Atlassian API token securely
- `write-actions` — allow reviewed issue creation actions
- `user-configured-domains` — call the Atlassian hostname entered during setup
- `background-refresh` — run scheduled project checks

## What it does not do

- Does not replace Jira boards, reports, releases, or planning views
- Does not transition issues automatically in v1
- Does not delete issues, comments, or attachments
- Does not send Jira notifications directly

## Setup

1. In Atlassian, create an API token for the account that should read and create issues.
2. Install **Jira** from the Status plugin store.
3. Create a configured app with the Atlassian site, project key, email, and API token.
4. Grant network, keychain, background refresh, and write action permissions as needed.
5. Run **Refresh Jira issues** once, then choose dashboard tile fields in the app settings.
