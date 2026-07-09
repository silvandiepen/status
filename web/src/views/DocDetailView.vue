<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { useBemm } from 'bemm'
import DocsPageLayout from '@/components/DocsPageLayout.vue'
import MarkdownContent from '@/components/MarkdownContent.vue'
import SiteLayout from '@/components/SiteLayout.vue'
import docsData from '@/generated/docs.json'

const bemm = useBemm('doc-page', { return: 'string' })

const route = useRoute()

const document = computed(() => {
  const slug = String(route.params.docSlug ?? '')
  return docsData.documents.find((candidate) => candidate.slug === slug)
})
</script>

<template>
  <SiteLayout>
    <main :class="bemm()">
      <template v-if="document">
        <DocsPageLayout :sections="document.toc">
          <header :class="bemm('header')">
            <p :class="bemm('eyebrow')">Docs</p>
            <h1 :class="bemm('title')">{{ document.title }}</h1>
            <p :class="bemm('summary')">{{ document.summary }}</p>
            <div :class="bemm('links')">
              <RouterLink to="/docs/">All docs</RouterLink>
              <a :href="document.sourceUrl" target="_blank" rel="noopener">Open on GitHub</a>
            </div>
          </header>

          <MarkdownContent :html="document.html" />
        </DocsPageLayout>
      </template>

      <template v-else>
        <DocsPageLayout>
          <header :class="bemm('header')">
            <p :class="bemm('eyebrow')">Docs</p>
            <h1 :class="bemm('title')">Document not found.</h1>
            <p :class="bemm('summary')">
              The requested documentation page is not part of the published docs index.
            </p>
            <div :class="bemm('links')">
              <RouterLink to="/docs/">All docs</RouterLink>
            </div>
          </header>
        </DocsPageLayout>
      </template>
    </main>
  </SiteLayout>
</template>

<style lang="scss">
.doc-page {
  background: var(--color-bg);
  color: var(--color-text-primary);

  &__header {
    margin-bottom: var(--space-l);
  }

  &__eyebrow {
    color: var(--color-accent);
    font-size: var(--font-size-sm);
    font-weight: var(--font-weight-semibold);
    margin-bottom: var(--space-s);
  }

  &__title {
    font-size: clamp(28px, 3.5vw, 40px);
    font-weight: var(--font-weight-bold);
    letter-spacing: -0.02em;
    line-height: var(--line-height-tight);
    margin-bottom: var(--space-s);
  }

  &__summary {
    color: var(--color-text-secondary);
    font-size: var(--font-size-base);
    line-height: var(--line-height-relaxed);
    margin-bottom: var(--space-m);
    max-width: 72ch;
  }

  &__links {
    display: flex;
    flex-wrap: wrap;
    gap: var(--space-s);

    a {
      border: 1px solid var(--color-border);
      border-radius: 999px;
      color: var(--color-foreground);
      font-size: var(--font-size-sm);
      font-weight: var(--font-weight-semibold);
      padding: var(--space-s) var(--space-m);
      text-decoration: none;
      transition: border-color var(--transition-fast), color var(--transition-fast);

      &:hover {
        border-color: var(--color-accent);
        color: var(--color-accent);
      }
    }
  }
}
</style>