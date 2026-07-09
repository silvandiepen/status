# Google Play Plugin

The Google Play plugin is an official Status plugin for Android apps published through Google Play Console.

It is read-only in Status v1. It does not reply to reviews, edit store listings, submit releases, change tracks, or modify billing state.

## What It Shows

- recent Google Play reviews for a configured package name;
- review star ratings and reviewer language;
- app version and Android version fields when Google returns them;
- low-rating review events that can be routed to notifications or the Status inbox.

## Authentication

This plugin uses Google OAuth 2 with PKCE. Status opens the Google authorization page, receives the `status://oauth/googleplay` callback, stores the token set in Keychain, and injects request authorization headers at runtime.

The OAuth account must have access to the target app in Google Play Console.

## Setup

1. Install the Google Play plugin.
2. Grant Network, Keychain, OAuth, and Background Refresh permissions.
3. Connect a Google account through OAuth.
4. Enter the Android package name, for example `com.example.app`.
5. Save the app.
6. Run a manual refresh or let the scheduled review check run.

## Boundaries

Status is not a replacement for Google Play Console. This plugin surfaces operational signals that are useful in a personal status dashboard and links back to the source system for deeper work.

Official Status plugins should:

- use declarative requests and mappings only;
- keep write actions out of v1 unless the action is explicit, reversible, and audited;
- store tokens only through Status Keychain references;
- emit normalized resources, events, and metrics;
- document setup requirements and source-system permissions.
