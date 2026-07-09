<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { Badge } from '@sil/ui'
import { useBemm } from 'bemm'

import docsData from '../generated/docs.json'

const bemm = useBemm('doc-detail-view', { return: 'string' })
const route = useRoute()

const document = computed(() => {
  const slug = String(route.params.docSlug ?? '')
  return docsData.documents.find((candidate) => candidate.slug === slug)
})
</script>

<template>
  <main :class="bemm()">
    <template v-if="document">
      <section :class="bemm('intro')">
        <Badge variant="outline">Docs</Badge>
        <h1>{{ document.title }}</h1>
        <p>{{ document.summary }}</p>
        <div :class="bemm('links')">
          <RouterLink to="/docs/">All docs</RouterLink>
          <a :href="document.sourceUrl">Open on GitHub</a>
        </div>
      </section>

      <article :class="bemm('article')">
        <pre>{{ document.content }}</pre>
      </article>
    </template>

    <section v-else :class="bemm('intro')">
      <Badge variant="outline">Docs</Badge>
      <h1>Document not found.</h1>
      <p>The requested documentation page is not part of the published docs index.</p>
      <RouterLink to="/docs/">All docs</RouterLink>
    </section>
  </main>
</template>
