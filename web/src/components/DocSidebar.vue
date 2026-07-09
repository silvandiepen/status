<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { useBemm } from 'bemm'
import docsIndex from '@/generated/docs-index.json'

export type DocTocEntry = {
  id: string
  text: string
  depth: number
}

const props = defineProps<{
  sections?: DocTocEntry[]
}>()

const bemm = useBemm('doc-sidebar', { return: 'string' })
const route = useRoute()

const documents = docsIndex.documents
const activeSlug = computed(() => String(route.params.docSlug ?? ''))
const sectionLinks = computed(() => props.sections?.filter((entry) => entry.depth <= 3) ?? [])
</script>

<template>
  <aside :class="bemm()">
    <nav :class="bemm('nav')" aria-label="Documentation">
      <div :class="bemm('group')">
        <p :class="bemm('label')">Documentation</p>
        <ul :class="bemm('list')">
          <li v-for="document in documents" :key="document.slug">
            <RouterLink
              :to="document.path"
              :class="[bemm('link'), { [bemm('link', 'active')]: document.slug === activeSlug }]"
            >
              {{ document.title }}
            </RouterLink>
          </li>
        </ul>
      </div>

      <div v-if="sectionLinks.length" :class="bemm('group')">
        <p :class="bemm('label')">On this page</p>
        <ul :class="[bemm('list'), bemm('list', 'sections')]">
          <li
            v-for="section in sectionLinks"
            :key="section.id"
            :class="bemm('section-item', String(section.depth))"
          >
            <a :href="`#${section.id}`" :class="bemm('section-link')">
              {{ section.text }}
            </a>
          </li>
        </ul>
      </div>
    </nav>
  </aside>
</template>

<style lang="scss">
.doc-sidebar {
  position: sticky;
  top: calc(var(--space-l) + var(--space-m));
  align-self: start;
  max-height: calc(100vh - var(--space-xxl));
  overflow-y: auto;
  padding-right: var(--space-s);

  &__nav {
    display: grid;
    gap: var(--space-l);
  }

  &__group {
    display: grid;
    gap: var(--space-s);
  }

  &__label {
    color: var(--color-text-tertiary);
    font-size: var(--font-size-xs);
    font-weight: var(--font-weight-semibold);
    letter-spacing: 0.06em;
    text-transform: uppercase;
  }

  &__list {
    display: grid;
    gap: var(--space-xs);
    list-style: none;
    margin: 0;
    padding: 0;
  }

  &__link {
    border-left: 2px solid transparent;
    color: var(--color-text-secondary);
    display: block;
    font-size: var(--font-size-sm);
    line-height: var(--line-height-normal);
    padding: var(--space-xs) 0 var(--space-xs) var(--space-s);
    text-decoration: none;
    transition: border-color var(--transition-fast), color var(--transition-fast);

    &:hover {
      color: var(--color-text-primary);
    }

    &--active {
      border-left-color: var(--color-accent);
      color: var(--color-text-primary);
      font-weight: var(--font-weight-semibold);
    }
  }

  &__section-link {
    color: var(--color-text-secondary);
    display: block;
    font-size: var(--font-size-sm);
    line-height: var(--line-height-normal);
    padding: 2px 0;
    text-decoration: none;
    transition: color var(--transition-fast);

    &:hover {
      color: var(--color-accent);
    }
  }

  &__section-item--3 {
    padding-left: var(--space-s);
  }

  &__section-item--4,
  &__section-item--5,
  &__section-item--6 {
    padding-left: var(--space-m);
  }
}
</style>