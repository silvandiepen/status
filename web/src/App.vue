<script setup lang="ts">
import { useBemm } from 'bemm'

const bemm = useBemm('site-shell', { return: 'string' })
</script>

<template>
  <div :class="bemm()">
    <header :class="bemm('header')">
      <RouterLink :class="bemm('brand')" to="/">
        Status
      </RouterLink>
      <nav :class="bemm('nav')" aria-label="Primary navigation">
        <RouterLink to="/download/">Download</RouterLink>
        <RouterLink to="/plugins/">Plugins</RouterLink>
        <RouterLink to="/developers/">Developers</RouterLink>
        <RouterLink to="/docs/">Docs</RouterLink>
      </nav>
    </header>

    <RouterView />

    <footer :class="bemm('footer')">
      <RouterLink to="/privacy/">Privacy and security</RouterLink>
      <RouterLink to="/changelog/">Changelog</RouterLink>
      <a href="https://status-registry.hakobs.com/v1/plugins">Registry API</a>
    </footer>
  </div>
</template>
