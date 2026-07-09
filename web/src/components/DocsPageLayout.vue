<script setup lang="ts">
import { useBemm } from 'bemm'
import DocSidebar, { type DocTocEntry } from '@/components/DocSidebar.vue'

defineProps<{
  sections?: DocTocEntry[]
}>()

const bemm = useBemm('docs-layout', { return: 'string' })
</script>

<template>
  <div :class="bemm()">
    <DocSidebar :sections="sections" />
    <div :class="bemm('content')">
      <slot />
    </div>
  </div>
</template>

<style lang="scss">
.docs-layout {
  display: grid;
  gap: var(--space-xl);
  grid-template-columns: minmax(200px, 240px) minmax(0, 1fr);
  margin: 0 auto;
  max-width: 1280px;
  padding: calc(var(--space-xl) + var(--space-l)) var(--space-l) var(--space-xxl);
  width: 100%;

  &__content {
    min-width: 0;
  }

  @media (max-width: 900px) {
    gap: var(--space-l);
    grid-template-columns: 1fr;
    padding-top: var(--space-xl);

    .doc-sidebar {
      max-height: none;
      overflow: visible;
      padding-right: 0;
      position: static;
    }
  }
}
</style>