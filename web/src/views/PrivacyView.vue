<script setup lang="ts">
import { Badge, Card } from '@sil/ui'
import { useBemm } from 'bemm'

const bemm = useBemm('privacy-view', { return: 'string' })

const privacy = [
  'Status is local-first for v1; operational data is stored on the device by default.',
  'Credentials belong in platform keychain storage and are never exposed to plugin packages.',
  'Plugins declare network domains and permissions before installation.',
  'Write actions require explicit user permission and produce audit log entries.',
]

const security = [
  'Registry packages include immutable hashes and signature metadata.',
  'Official and reviewed plugins are distributed through Cloudflare R2 and the registry API.',
  'Plugin manifests are validated before publishing and again before install.',
  'Dangerous actions such as deletes, billing changes, and automatic submissions are out of v1 scope.',
]
</script>

<template>
  <main :class="bemm()">
    <section :class="bemm('intro')">
      <Badge variant="outline">Privacy and security</Badge>
      <h1>Local-first operations with explicit permissions.</h1>
      <p>
        Status treats integrations as declarative data sources. The app owns credentials, UI, notifications,
        automation decisions, and audit output.
      </p>
    </section>

    <section :class="bemm('grid')">
      <Card title="Privacy posture">
        <ul>
          <li v-for="item in privacy" :key="item">{{ item }}</li>
        </ul>
      </Card>
      <Card title="Registry safety">
        <ul>
          <li v-for="item in security" :key="item">{{ item }}</li>
        </ul>
      </Card>
    </section>
  </main>
</template>
