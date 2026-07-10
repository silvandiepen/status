export const registry = {
  "schemaVersion": "1.0.0",
  "plugins": [
    {
      "id": "com.status.appstoreconnect",
      "name": "App Store Connect",
      "summary": "Track app review, builds, and release status.",
      "description": "Read-only App Store Connect status events for apps, review state, build processing, and release readiness.",
      "category": "developer",
      "icon": "sf:app.badge",
      "accentColor": "#2F80ED",
      "author": {
        "name": "Status Foundry",
        "publisherId": "status-foundry",
        "websitePath": "/publishers/status-foundry/",
        "externalUrl": "https://github.com/statusfoundry",
        "repositoryUrl": "https://github.com/statusfoundry/status",
        "publisherSummary": "Official Status integrations and reference plugin packages."
      },
      "trustLevel": "official",
      "permissions": [
        "network",
        "keychain",
        "private-key",
        "background-refresh"
      ],
      "domains": [
        "api.appstoreconnect.apple.com"
      ],
      "versions": [
        {
          "version": "0.1.0",
          "minCoreVersion": "0.1.0",
          "platforms": [
            "macOS",
            "iOS"
          ],
          "packageUrl": "https://status-registry.hakobs.com/plugins/com.status.appstoreconnect/0.1.0/com.status.appstoreconnect-0.1.0.statusplugin.zip",
          "manifestUrl": "https://status-registry.hakobs.com/plugins/com.status.appstoreconnect/0.1.0/manifest.json",
          "sha256": "85927fcc97f885de148dac273addac38c6541ef10514f29dcbab9ae6469493ff",
          "signature": "0P95/9QeX0nx0fpvGRXIWKAUzbHLgbnjjhZfEFzUyyJAjlPTvfGM2orjib7+kG3hpQ7PftfWjtPN1i47uGZKAA==",
          "signedBy": "status-foundry-dev",
          "releasedAt": "2026-07-07T12:00:00Z"
        }
      ]
    },
    {
      "id": "com.status.github",
      "name": "GitHub",
      "summary": "Track workflow failures, pull requests, and issue activity.",
      "description": "Read-only GitHub repository events for workflow failures, pull requests, and issue activity.",
      "category": "developer",
      "icon": "sf:chevron.left.forwardslash.chevron.right",
      "accentColor": "#4B5563",
      "author": {
        "name": "Status Foundry",
        "publisherId": "status-foundry",
        "websitePath": "/publishers/status-foundry/",
        "externalUrl": "https://github.com/statusfoundry",
        "repositoryUrl": "https://github.com/statusfoundry/status",
        "publisherSummary": "Official Status integrations and reference plugin packages."
      },
      "trustLevel": "official",
      "permissions": [
        "network",
        "keychain",
        "background-refresh"
      ],
      "domains": [
        "api.github.com"
      ],
      "versions": [
        {
          "version": "0.1.0",
          "minCoreVersion": "0.1.0",
          "platforms": [
            "macOS",
            "iOS"
          ],
          "packageUrl": "https://status-registry.hakobs.com/plugins/com.status.github/0.1.0/com.status.github-0.1.0.statusplugin.zip",
          "manifestUrl": "https://status-registry.hakobs.com/plugins/com.status.github/0.1.0/manifest.json",
          "sha256": "29077ef800ee2eb02ada48c81511bada27bae1729ed26fdcc218de33d2e60726",
          "signature": "kbieWrt6+/IpD49NBdKWuGX5ofZXFstS6kB2PnkHgZ3UTt9T5BcP7/fz+I5NAC88SThej86MLEpFTuVDe0g0Bg==",
          "signedBy": "status-foundry-dev",
          "releasedAt": "2026-07-07T12:00:00Z"
        }
      ]
    },
    {
      "id": "com.status.gitlab",
      "name": "GitLab",
      "summary": "Track GitLab pipelines, merge requests, issues, and project activity.",
      "description": "Read-only GitLab project events for failed pipelines, merge requests, issues, and project activity.",
      "category": "developer",
      "icon": "sf:shippingbox",
      "accentColor": "#FC6D26",
      "author": {
        "name": "Status Foundry",
        "publisherId": "status-foundry",
        "websitePath": "/publishers/status-foundry/",
        "externalUrl": "https://github.com/statusfoundry",
        "repositoryUrl": "https://github.com/statusfoundry/status",
        "publisherSummary": "Official Status integrations and reference plugin packages."
      },
      "trustLevel": "official",
      "permissions": [
        "network",
        "keychain",
        "background-refresh"
      ],
      "domains": [
        "gitlab.com"
      ],
      "versions": [
        {
          "version": "0.1.0",
          "minCoreVersion": "0.1.0",
          "platforms": [
            "macOS",
            "iOS"
          ],
          "packageUrl": "https://status-registry.hakobs.com/plugins/com.status.gitlab/0.1.0/com.status.gitlab-0.1.0.statusplugin.zip",
          "manifestUrl": "https://status-registry.hakobs.com/plugins/com.status.gitlab/0.1.0/manifest.json",
          "sha256": "ce3a6db89337cd4b8c1c03b9d006812a97d891534842326368c80b5be161335b",
          "signature": "es9FSnA3PgBFw7LLY+jqfaRR/i4pa3iIau0ZEjwWcOFQDpihYQZsvrvWKftbnTWUECQVXK96cHarNmhS60qlCQ==",
          "signedBy": "status-foundry-dev",
          "releasedAt": "2026-07-09T12:00:00Z"
        }
      ]
    },
    {
      "id": "com.status.googleplay",
      "name": "Google Play",
      "summary": "Track Google Play reviews and low-rating app feedback.",
      "description": "Read-only Google Play Console status for Android app reviews, ratings, and release-facing signals.",
      "category": "developer",
      "icon": "sf:play.square.stack",
      "accentColor": "#34A853",
      "author": {
        "name": "Status Foundry",
        "publisherId": "status-foundry",
        "websitePath": "/publishers/status-foundry/",
        "externalUrl": "https://github.com/statusfoundry",
        "repositoryUrl": "https://github.com/statusfoundry/status",
        "publisherSummary": "Official Status integrations and reference plugin packages."
      },
      "trustLevel": "official",
      "permissions": [
        "network",
        "keychain",
        "oauth",
        "background-refresh"
      ],
      "domains": [
        "accounts.google.com",
        "oauth2.googleapis.com",
        "androidpublisher.googleapis.com"
      ],
      "versions": [
        {
          "version": "0.1.0",
          "minCoreVersion": "0.1.0",
          "platforms": [
            "macOS",
            "iOS"
          ],
          "packageUrl": "https://status-registry.hakobs.com/plugins/com.status.googleplay/0.1.0/com.status.googleplay-0.1.0.statusplugin.zip",
          "manifestUrl": "https://status-registry.hakobs.com/plugins/com.status.googleplay/0.1.0/manifest.json",
          "sha256": "09e3f2b61f88a5cdbff281377e942984028d961ed370e29fc83f3153fe96ce1a",
          "signature": "0s/n9CTq4CPZV1p6K+nSHHz+XyXvAxKM/J39pMJq6rHwdCszw1OgZR5wmT7Sfo6vhAnriBVFFCzKD8PHFiw6AA==",
          "signedBy": "status-foundry-dev",
          "releasedAt": "2026-07-09T12:00:00Z"
        }
      ]
    },
    {
      "id": "com.status.jira",
      "name": "Jira",
      "summary": "Track Jira project issues and create follow-up issues from Status automations.",
      "description": "Read Jira project issues and create controlled follow-up issues from Status rules.",
      "category": "developer",
      "icon": "sf:checklist",
      "accentColor": "#0C66E4",
      "author": {
        "name": "Status Foundry",
        "publisherId": "status-foundry",
        "websitePath": "/publishers/status-foundry/",
        "externalUrl": "https://github.com/statusfoundry",
        "repositoryUrl": "https://github.com/statusfoundry/status",
        "publisherSummary": "Official Status integrations and reference plugin packages."
      },
      "trustLevel": "official",
      "permissions": [
        "network",
        "keychain",
        "write-actions",
        "user-configured-domains",
        "background-refresh"
      ],
      "domains": [],
      "versions": [
        {
          "version": "0.1.0",
          "minCoreVersion": "0.1.0",
          "platforms": [
            "macOS",
            "iOS"
          ],
          "packageUrl": "https://status-registry.hakobs.com/plugins/com.status.jira/0.1.0/com.status.jira-0.1.0.statusplugin.zip",
          "manifestUrl": "https://status-registry.hakobs.com/plugins/com.status.jira/0.1.0/manifest.json",
          "sha256": "eedd93e491da7e2cf20e0765be1e33e75fdf21e24b7cfc479d430b5cbe3fd43b",
          "signature": "SQS/In7BkAATsc88OiskYqs8qmdY1EnzKjRjZ8YxjNx3n4ZRWhUVlXgUo7wC+loNsj9xLq3TGAk9hAde0usdAw==",
          "signedBy": "status-foundry-dev",
          "releasedAt": "2026-07-09T12:00:00Z"
        }
      ]
    },
    {
      "id": "com.status.website",
      "name": "Website Uptime",
      "summary": "Track website health and response status.",
      "description": "Declarative uptime checks for sites and endpoints the user chooses to track.",
      "category": "monitoring",
      "icon": "sf:globe",
      "accentColor": "#16A34A",
      "author": {
        "name": "Status Foundry",
        "publisherId": "status-foundry",
        "websitePath": "/publishers/status-foundry/",
        "externalUrl": "https://github.com/statusfoundry",
        "repositoryUrl": "https://github.com/statusfoundry/status",
        "publisherSummary": "Official Status integrations and reference plugin packages."
      },
      "trustLevel": "official",
      "permissions": [
        "network",
        "user-configured-domains",
        "background-refresh"
      ],
      "domains": [],
      "versions": [
        {
          "version": "0.1.0",
          "minCoreVersion": "0.1.0",
          "platforms": [
            "macOS",
            "iOS"
          ],
          "packageUrl": "https://status-registry.hakobs.com/plugins/com.status.website/0.1.0/com.status.website-0.1.0.statusplugin.zip",
          "manifestUrl": "https://status-registry.hakobs.com/plugins/com.status.website/0.1.0/manifest.json",
          "sha256": "f37e02d33b31d5ba57b0a1da94d76edf5d2845552f517a0796f1b87b7996148c",
          "signature": "4B2MDnPrH6gT2CCy1QRbiifxSb5sd6cus0izHWGnHHaV0fJYctnpwGWXS2OdtZzJONVPfJV3EMw4wFvEM7SeCg==",
          "signedBy": "status-foundry-dev",
          "releasedAt": "2026-07-07T12:00:00Z"
        }
      ]
    },
    {
      "id": "com.status.youtube",
      "name": "YouTube",
      "summary": "Track YouTube channel status, latest uploads, and creator metrics.",
      "description": "Read-only YouTube channel status for creator accounts, latest uploads, subscriber counts, and channel-level signals.",
      "category": "content",
      "icon": "sf:play.rectangle",
      "accentColor": "#FF0033",
      "author": {
        "name": "Status Foundry",
        "publisherId": "status-foundry",
        "websitePath": "/publishers/status-foundry/",
        "externalUrl": "https://github.com/statusfoundry",
        "repositoryUrl": "https://github.com/statusfoundry/status",
        "publisherSummary": "Official Status integrations and reference plugin packages."
      },
      "trustLevel": "official",
      "permissions": [
        "network",
        "keychain",
        "oauth",
        "background-refresh"
      ],
      "domains": [
        "accounts.google.com",
        "oauth2.googleapis.com",
        "www.googleapis.com"
      ],
      "versions": [
        {
          "version": "0.1.0",
          "minCoreVersion": "0.1.0",
          "platforms": [
            "macOS",
            "iOS"
          ],
          "packageUrl": "https://status-registry.hakobs.com/plugins/com.status.youtube/0.1.0/com.status.youtube-0.1.0.statusplugin.zip",
          "manifestUrl": "https://status-registry.hakobs.com/plugins/com.status.youtube/0.1.0/manifest.json",
          "sha256": "8f2d75e8626fb2e005bb7df179c4e47a0c37bba81fc2952a0d6e75aef8e30ca5",
          "signature": "vnifiQdRgEeAik1ryGRCkQDMycgw7xJ1/twE0jzbBToZlCFIpfH4O8TYYb52nV0FeFkknbFNResD3ISavYMuBg==",
          "signedBy": "status-foundry-dev",
          "releasedAt": "2026-07-09T12:00:00Z"
        }
      ]
    }
  ]
};


export const revocations = {
  "schemaVersion": "1.0.0",
  "revokedPlugins": [],
  "revokedVersions": [],
  "revokedHashes": [],
  "revokedSigningKeys": []
};
