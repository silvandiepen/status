<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { Badge, Card } from '@sil/ui'
import { useBemm } from 'bemm'

import registryData from '../generated/registry.json'

const bemm = useBemm('plugin-detail-view', { return: 'string' })
const route = useRoute()

const plugin = computed(() => {
  const pluginId = String(route.params.pluginId ?? '')
  return registryData.plugins.find((candidate) => candidate.id === pluginId)
})

const release = computed(() => plugin.value?.versions[0])
const trustLabel = computed(() => {
  if (plugin.value?.trustLevel === 'official') {
    return 'Official'
  }
  if (plugin.value?.trustLevel === 'verified-third-party') {
    return 'Verified third party'
  }
  return 'Local'
})

const permissionList = computed(() => plugin.value?.permissions.join(', ') || 'No elevated permissions')
const domainList = computed(() => plugin.value?.domains.join(', ') || 'User-configured domains')
</script>

<template>
  <main :class="bemm()">
    <template v-if="plugin">
      <section :class="bemm('intro')">
        <Badge variant="outline">{{ trustLabel }}</Badge>
        <h1>{{ plugin.name }}</h1>
        <p>{{ plugin.description }}</p>
      </section>

      <section :class="bemm('grid')">
        <Card title="Package">
          <dl :class="bemm('facts')">
            <div>
              <dt>Plugin ID</dt>
              <dd>{{ plugin.id }}</dd>
            </div>
            <div>
              <dt>Version</dt>
              <dd>{{ release?.version ?? 'No release' }}</dd>
            </div>
            <div>
              <dt>Author</dt>
              <dd>{{ plugin.author }}</dd>
            </div>
            <div>
              <dt>Category</dt>
              <dd>{{ plugin.category }}</dd>
            </div>
          </dl>
        </Card>

        <Card title="Trust checks">
          <dl :class="bemm('facts')">
            <div>
              <dt>Permissions</dt>
              <dd>{{ permissionList }}</dd>
            </div>
            <div>
              <dt>Domains</dt>
              <dd>{{ domainList }}</dd>
            </div>
            <div>
              <dt>Signed by</dt>
              <dd>{{ release?.signedBy ?? 'Pending signature' }}</dd>
            </div>
            <div>
              <dt>SHA-256</dt>
              <dd>{{ release?.sha256 ?? 'Pending package' }}</dd>
            </div>
          </dl>
        </Card>
      </section>

      <section :class="bemm('links')" aria-label="Distribution links">
        <a v-if="release?.manifestUrl" :href="release.manifestUrl">Manifest</a>
        <a v-if="release?.packageUrl" :href="release.packageUrl">Package</a>
        <a href="/plugins/">Back to plugins</a>
      </section>
    </template>

    <section v-else :class="bemm('intro')">
      <Badge variant="outline">Plugin</Badge>
      <h1>Plugin not found.</h1>
      <p>The registry does not list this plugin.</p>
      <a href="/plugins/">Back to plugins</a>
    </section>
  </main>
</template>
