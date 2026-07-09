<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { useBemm } from 'bemm'
import SiteLayout from '@/components/SiteLayout.vue'
import publishersData from '@/generated/publishers.json'

const bemm = useBemm('page', { return: 'string' })
const directoryBemm = useBemm('plugins-directory', { return: 'string' })

const route = useRoute()

const publisher = computed(() => {
  const publisherId = String(route.params.publisherId ?? '')
  return publishersData.publishers.find((candidate) => candidate.id === publisherId)
})
</script>

<template>
  <SiteLayout>
    <main :class="bemm()">
      <template v-if="publisher">
        <section :class="bemm('intro')">
          <div :class="bemm('container')">
            <p :class="bemm('eyebrow')">Publisher</p>
            <h1 :class="bemm('title')">{{ publisher.name }}</h1>
            <p :class="bemm('subtitle')">{{ publisher.summary }}</p>
            <div :class="bemm('links')">
              <RouterLink to="/plugins/">All plugins</RouterLink>
              <a v-if="publisher.websiteUrl" :href="publisher.websiteUrl" target="_blank" rel="noopener">Website</a>
              <a v-if="publisher.repositoryUrl" :href="publisher.repositoryUrl" target="_blank" rel="noopener">Repository</a>
            </div>
          </div>
        </section>

        <section :class="bemm('body')">
          <div :class="bemm('container')">
            <article :class="bemm('card')">
              <h2>About</h2>
              <p>{{ publisher.description }}</p>
            </article>

            <div :class="directoryBemm()" aria-label="Publisher plugins">
              <h2 :class="directoryBemm('section-title')">Plugins</h2>
              <article v-for="plugin in publisher.plugins" :key="plugin.id" :class="directoryBemm('item')">
                <div :class="directoryBemm('head')">
                  <div>
                    <h3>{{ plugin.name }}</h3>
                    <p>{{ plugin.summary }}</p>
                  </div>
                  <span :class="directoryBemm('badge')">{{ plugin.published ? 'Registry' : 'Template' }}</span>
                </div>
                <RouterLink :class="directoryBemm('link')" :to="plugin.websitePath">
                  Read plugin docs
                </RouterLink>
              </article>
            </div>
          </div>
        </section>
      </template>

      <template v-else>
        <section :class="bemm('intro')">
          <div :class="bemm('container')">
            <p :class="bemm('eyebrow')">Publisher</p>
            <h1 :class="bemm('title')">Publisher not found.</h1>
            <p :class="bemm('subtitle')">This publisher is not part of the website index.</p>
            <div :class="bemm('links')">
              <RouterLink to="/plugins/">All plugins</RouterLink>
            </div>
          </div>
        </section>
      </template>
    </main>
  </SiteLayout>
</template>