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
      "author": "Status Foundry",
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
          "sha256": "bd33531a3265386201208a2c2765b44375d6845ce811163db31c112d2478a5ea",
          "signature": "BunCY8njb11OWT1JUpdVUv+WzuZb+Cm3aq7/hT8yntFb1k2Hhfw50MPHEAg5IFqGF/WyNwvmiWc3omG6ydLsBg==",
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
      "author": "Status Foundry",
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
          "sha256": "e8985720b4553e0b61737c5e25fcdad528ff69b972d6b2151d761b8a20623dda",
          "signature": "D0K8ItAuwSir2LwkI9SD2JSAW9039qeJkGLoJ2Bm2ltQgqN5zZupR3C3ii4EHK7NT5wIkEZCHvuxVgTKvixgBg==",
          "signedBy": "status-foundry-dev",
          "releasedAt": "2026-07-07T12:00:00Z"
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
      "author": "Status Foundry",
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
          "sha256": "f0ce6b3ed640f0d12eeae201f3a8ca00359e668838bf912cbc3c0f42319e114b",
          "signature": "iww0Veyc7yiJxC+HDHAllxPflBxkuS1+FWlSZLJH4fe9kWvUHa2mWbtIcj01rfxNt/ncU5+ylaM0ylLqQcuxAw==",
          "signedBy": "status-foundry-dev",
          "releasedAt": "2026-07-07T12:00:00Z"
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
