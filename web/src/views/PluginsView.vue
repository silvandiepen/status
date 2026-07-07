<script setup lang="ts">
import { Badge, Card } from '@sil/ui'
import { useBemm } from 'bemm'

const bemm = useBemm('plugins-view', { return: 'string' })

const registryChecks = [
  'Local hash verification',
  'Package signature verification',
  'Compatibility checks',
  'Permission review',
  'Revocation checks',
]
</script>

<template>
  <main :class="bemm()">
    <section :class="bemm('intro')">
      <Badge variant="outline">Plugins</Badge>
      <h1>Reviewed, signed plugin distribution.</h1>
      <p>
        Official and reviewed third-party plugins are published through the registry only after validation,
        review, signing, and immutable R2 upload.
      </p>
    </section>

    <section :class="bemm('grid')">
      <Card title="Registry API">
        <p>
          <a href="https://status-registry.hakobs.com/v1/plugins">status-registry.hakobs.com/v1/plugins</a>
        </p>
      </Card>
      <Card title="Trust model">
        <ul>
          <li v-for="check in registryChecks" :key="check">{{ check }}</li>
        </ul>
      </Card>
    </section>
  </main>
</template>
