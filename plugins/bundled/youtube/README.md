# YouTube

## Why install this plugin

Install YouTube when you want Status to keep a calm, read-only view of creator account health across your channels. It is designed for quick operational awareness: latest uploads, basic channel statistics, visibility state, and direct links back to YouTube Studio.

Status does not replace YouTube Studio. The plugin only normalizes the small set of signals that help you notice what changed and where to act next.

## What Status shows

- Connected channels and their current public/private visibility state.
- Subscriber, view, and video counts reported by the YouTube Data API.
- Recently published uploads for the connected Google account.
- Links back to YouTube Studio and the public video page.
- Dashboard and inbox signals when a channel is not public.

## Authentication

This plugin uses Google OAuth 2 with PKCE. Status opens the provider authorization page, receives the `status://oauth/youtube` callback, stores the token set in Keychain, and injects request authorization headers at runtime.

Required scope:

```txt
https://www.googleapis.com/auth/youtube.readonly
```

## Setup

1. Install **YouTube** from the Status plugin catalog.
2. Grant Network, Keychain, OAuth, and Background Refresh permissions.
3. Open app settings and choose **Connect YouTube**.
4. Sign in with the Google account that can view the channel.
5. Save the app with a clear name, for example `Hakobs YouTube`.

## Boundaries

Read-only in v1. The plugin does not upload videos, edit metadata, delete comments, change visibility, manage monetization, or send messages.
