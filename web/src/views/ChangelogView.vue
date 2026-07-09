<script setup lang="ts">
import { Badge, Card } from '@sil/ui'
import { useBemm } from 'bemm'

const bemm = useBemm('changelog-view', { return: 'string' })

const changes = [
  {
    version: '0.1.0',
    date: '2026-07-09',
    items: [
      'Native app shells, shared StatusCore package, local persistence, plugin loading, and event pipeline.',
      'Official declarative plugins for App Store Connect, GitHub, and website uptime.',
      'Cloudflare registry worker, R2 package layout, Pages website, and CI/deploy workflows.',
      'Notification preferences, notification history, provider-backed actions, and audit logging.',
    ],
  },
]
</script>

<template>
  <main :class="bemm()">
    <section :class="bemm('intro')">
      <Badge variant="outline">Changelog</Badge>
      <h1>Release notes for Status.</h1>
      <p>Public release notes will track app builds, registry changes, plugin updates, and security fixes.</p>
    </section>

    <section :class="bemm('list')" aria-label="Release notes">
      <Card v-for="change in changes" :key="change.version" :title="change.version" :class="bemm('item')">
        <p>{{ change.date }}</p>
        <ul>
          <li v-for="item in change.items" :key="item">{{ item }}</li>
        </ul>
      </Card>
    </section>
  </main>
</template>
