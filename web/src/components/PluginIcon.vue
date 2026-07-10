<script setup lang="ts">
import { computed } from 'vue'
import { useBemm } from 'bemm'

const props = withDefaults(
  defineProps<{
    name: string
    accentColor?: string | null
    iconSvg?: string | null
    size?: 'sm' | 'md' | 'lg'
  }>(),
  { accentColor: null, iconSvg: null, size: 'md' },
)

const bemm = useBemm('plugin-icon', { return: 'string' })

const initial = computed(() => props.name?.trim()?.charAt(0)?.toUpperCase() ?? '?')
const tileColor = computed(() => props.accentColor || 'var(--color-accent)')
</script>

<template>
  <span
    :class="[bemm(), bemm('', size)]"
    :style="{ '--plugin-accent': tileColor }"
  >
    <span v-if="iconSvg" :class="bemm('shape')" v-html="iconSvg" />
    <span v-else :class="bemm('fallback')">
      {{ initial }}
    </span>
  </span>
</template>

<style lang="scss">
.plugin-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  border-radius: var(--radius-md);
  overflow: hidden;
  background: var(--plugin-accent);
  color: #fff;

  &--sm {
    width: 32px;
    height: 32px;
  }

  &--md {
    width: 48px;
    height: 48px;
  }

  &--lg {
    width: 64px;
    height: 64px;
  }

  &__shape {
    display: flex;
    width: 60%;
    height: 60%;

    svg {
      width: 100%;
      height: 100%;
      display: block;
    }
  }

  &__fallback {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 100%;
    height: 100%;
    font-weight: var(--font-weight-bold);
    letter-spacing: -0.02em;
  }

  &--sm &__fallback {
    font-size: var(--font-size-base);
  }

  &--md &__fallback {
    font-size: var(--font-size-xl);
  }

  &--lg &__fallback {
    font-size: var(--font-size-xxl);
  }
}
</style>
