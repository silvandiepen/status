# Google Play

Read-only Google Play Console status for Android app reviews, ratings, and release-facing signals.

## Why install this plugin

Install Google Play when you publish Android apps and want review attention signals in Status without checking Play Console all day. Status turns new reviews, low ratings, and app-level review trends into native events, dashboard tiles, app detail views, and notification rules.

## What you configure

Create one configured app per Android package you want to watch:

- **Package name** - Android application ID such as `com.example.app`

Auth uses Google OAuth 2 with PKCE. Status owns the browser authorization flow, stores the token set in Keychain, and only calls declared Google API hosts for the configured package.

## What it exposes

### Resources

- **review** - Google Play user review records with rating, language, author, and review text context

### Events

| Event | Meaning | Default notification |
| --- | --- | --- |
| `googleplay.review.received` | A user review was returned for the configured app | Digest |
| `googleplay.review.needs_attention` | A low-rating review needs attention | Dashboard only |

### Views

- **Review overview** - rating and review counts for the configured app
- **Reviews** - recent review list with rating and text context
- **Attention** - low-rating reviews surfaced as app-owned alerts

### Checks

- **Check reviews** - cron schedule for review polling
- **Refresh reviews** - manual refresh on demand

## Suggested automations

Suggested rules install disabled. Enable presets if you want low-rating reviews added to the Status inbox or included in local notifications.

## Actions

Read-only in v1. Status does not reply to reviews, change release status, edit listings, or modify Play Console data.

## Permissions and domains

- `network` - call Google OAuth and Android Publisher HTTPS APIs
- `keychain` - store OAuth token references securely
- `oauth` - connect the configured app through Google OAuth 2 with PKCE
- `background-refresh` - run scheduled review checks
- **Domains:** `accounts.google.com`, `oauth2.googleapis.com`, `androidpublisher.googleapis.com`

## What it does not do

- Does not replace Google Play Console for release management
- Does not reply to reviews or change app metadata
- Does not submit builds, manage tracks, or alter rollout state
- Does not request undeclared Google API hosts

## Setup

1. Install **Google Play** from the Status plugin store.
2. Create a configured app and enter the Android package name.
3. Connect with Google OAuth using an account that can read the app in Play Console.
4. Grant network, keychain, OAuth, and background refresh permissions.
5. Run **Refresh reviews**, then enable **Check reviews** if you want scheduled polling.
