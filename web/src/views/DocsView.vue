<script setup lang="ts">
import { Badge, Card } from '@sil/ui'
import { useBemm } from 'bemm'

import docsData from '../generated/docs.json'

const bemm = useBemm('docs-view', { return: 'string' })
const documents = docsData.documents
</script>

<template>
  <main :class="bemm()">
    <section :class="bemm('intro')">
      <Badge variant="outline">Docs</Badge>
      <h1>Product doctrine and implementation contracts.</h1>
      <p>
        Status is documentation-led. These documents define the native app, plugin model, registry,
        automation boundaries, security posture, and validation expectations.
      </p>
    </section>

    <section :class="bemm('list')" aria-label="Documentation">
      <Card v-for="document in documents" :key="document.slug" :title="document.title" :class="bemm('item')">
        <p>{{ document.summary }}</p>
        <RouterLink :to="document.path">Read document</RouterLink>
      </Card>
    </section>
  </main>
</template>
