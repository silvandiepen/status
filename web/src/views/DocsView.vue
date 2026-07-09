<script setup lang="ts">
import { useBemm } from 'bemm'
import DocsPageLayout from '@/components/DocsPageLayout.vue'
import SiteLayout from '@/components/SiteLayout.vue'
import docsData from '@/generated/docs-index.json'

const bemm = useBemm('docs-index', { return: 'string' })
const docsCardBemm = useBemm('docs-card', { return: 'string' })

const documents = docsData.documents
</script>

<template>
  <SiteLayout>
    <main :class="bemm()">
      <DocsPageLayout>
        <header :class="bemm('header')">
          <p :class="bemm('eyebrow')">Docs</p>
          <h1 :class="bemm('title')">Product doctrine and implementation contracts.</h1>
          <p :class="bemm('summary')">
            Status is documentation-led. These documents define the native app, plugin model, registry,
            automation boundaries, security posture, and validation expectations.
          </p>
        </header>

        <div :class="bemm('list')">
          <article
            v-for="document in documents"
            :key="document.slug"
            :class="[bemm('card'), docsCardBemm()]"
          >
            <h2>{{ document.title }}</h2>
            <p>{{ document.summary }}</p>
            <RouterLink :to="document.path">Read document</RouterLink>
          </article>
        </div>
      </DocsPageLayout>
    </main>
  </SiteLayout>
</template>

<style lang="scss">
.docs-index {
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
    max-width: 72ch;
  }

  &__list {
    display: grid;
    gap: var(--space-m);
    grid-template-columns: repeat(2, minmax(0, 1fr));

    @media (max-width: 820px) {
      grid-template-columns: 1fr;
    }
  }

  &__card {
    background: var(--color-surface);
    border: 1px solid var(--color-border-light);
    border-radius: var(--radius-lg);
    box-shadow: var(--shadow-sm);
    padding: calc(var(--space-l) + var(--space-m));
    transition: border-color var(--transition-fast), box-shadow var(--transition-fast), transform var(--transition-fast);

    &:hover {
      border-color: var(--color-border);
      box-shadow: var(--shadow-md);
      transform: translateY(-2px);
    }

    h2 {
      font-size: var(--font-size-lg);
      font-weight: var(--font-weight-semibold);
      margin-bottom: var(--space-s);
    }

    p {
      color: var(--color-text-secondary);
      line-height: var(--line-height-relaxed);
    }

    a {
      display: inline-flex;
      font-weight: var(--font-weight-semibold);
      margin-top: var(--space-m);
    }
  }
}

.docs-card {
  min-height: 180px;
}
</style>