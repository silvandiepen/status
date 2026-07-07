<script setup lang="ts">
import { Badge, Card } from '@sil/ui'
import { useBemm } from 'bemm'

const bemm = useBemm('developers-view', { return: 'string' })

const steps = [
  'Create a declarative plugin package.',
  'Add fixtures and schema validation evidence.',
  'Open a pull request for review.',
  'Status signs and publishes approved packages.',
]
</script>

<template>
  <main :class="bemm()">
    <section :class="bemm('intro')">
      <Badge variant="outline">Developers</Badge>
      <h1>Declarative plugins only.</h1>
      <p>
        Plugins describe auth, requests, mappings, events, views, and actions. They do not run arbitrary code,
        own UI, or access secrets directly.
      </p>
    </section>

    <section :class="bemm('grid')">
      <Card title="Submission path">
        <ol>
          <li v-for="step in steps" :key="step">{{ step }}</li>
        </ol>
      </Card>
      <Card title="V1 restrictions">
        <p>No public upload form, no self-service publishing, and no custom plugin UI.</p>
      </Card>
    </section>
  </main>
</template>
