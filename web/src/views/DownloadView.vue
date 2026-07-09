<script setup lang="ts">
import { Badge, Card } from '@sil/ui'
import { useBemm } from 'bemm'

const bemm = useBemm('download-view', { return: 'string' })

const readiness = [
  'Native macOS and iOS shells build from the same Swift package.',
  'Plugin packages are declarative, signed, and validated before registry listing.',
  'Local persistence, notification preferences, action audit logs, and runtime status are implemented.',
]

const installSteps = [
  'Use the latest TestFlight or signed beta build when published.',
  'Install official plugins from the Status registry inside the app.',
  'Review permissions before connecting accounts or enabling actions.',
]
</script>

<template>
  <main :class="bemm()">
    <section :class="bemm('intro')">
      <Badge variant="outline">Beta</Badge>
      <h1>Native builds first, public binaries next.</h1>
      <p>
        Status is currently prepared as a source-available beta. Public macOS downloads and iOS TestFlight
        links will be added here after signing, notarization, and release review are ready.
      </p>
    </section>

    <section :class="bemm('grid')">
      <Card title="Current readiness">
        <ul>
          <li v-for="item in readiness" :key="item">{{ item }}</li>
        </ul>
      </Card>
      <Card title="Install flow">
        <ol>
          <li v-for="step in installSteps" :key="step">{{ step }}</li>
        </ol>
      </Card>
    </section>
  </main>
</template>
