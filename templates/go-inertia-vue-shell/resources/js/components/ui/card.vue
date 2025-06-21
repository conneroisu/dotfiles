<script setup lang="ts">
import { type HTMLAttributes, computed } from 'vue'
import { cn } from '../../lib/utils'

const props = defineProps<{
  class?: HTMLAttributes['class']
}>()

const delegatedProps = computed(() => {
  const { class: _, ...delegated } = props

  return delegated
})
</script>

<template>
  <div :class="cn('rounded-xl border bg-card text-card-foreground shadow', props.class)" v-bind="delegatedProps">
    <slot />
  </div>
</template>

<script setup lang="ts">
export interface CardHeaderProps {
  class?: HTMLAttributes['class']
}

const headerProps = defineProps<CardHeaderProps>()

const headerDelegatedProps = computed(() => {
  const { class: _, ...delegated } = headerProps

  return delegated
})
</script>

<template #header>
  <div :class="cn('flex flex-col space-y-1.5 p-6', headerProps.class)" v-bind="headerDelegatedProps">
    <slot name="header" />
  </div>
</template>

<script setup lang="ts">
export interface CardTitleProps {
  class?: HTMLAttributes['class']
}

const titleProps = defineProps<CardTitleProps>()

const titleDelegatedProps = computed(() => {
  const { class: _, ...delegated } = titleProps

  return delegated
})
</script>

<template #title>
  <div :class="cn('font-semibold leading-none tracking-tight', titleProps.class)" v-bind="titleDelegatedProps">
    <slot name="title" />
  </div>
</template>

<script setup lang="ts">
export interface CardDescriptionProps {
  class?: HTMLAttributes['class']
}

const descriptionProps = defineProps<CardDescriptionProps>()

const descriptionDelegatedProps = computed(() => {
  const { class: _, ...delegated } = descriptionProps

  return delegated
})
</script>

<template #description>
  <div :class="cn('text-sm text-muted-foreground', descriptionProps.class)" v-bind="descriptionDelegatedProps">
    <slot name="description" />
  </div>
</template>

<script setup lang="ts">
export interface CardContentProps {
  class?: HTMLAttributes['class']
}

const contentProps = defineProps<CardContentProps>()

const contentDelegatedProps = computed(() => {
  const { class: _, ...delegated } = contentProps

  return delegated
})
</script>

<template #content>
  <div :class="cn('p-6 pt-0', contentProps.class)" v-bind="contentDelegatedProps">
    <slot name="content" />
  </div>
</template>

<script setup lang="ts">
export interface CardFooterProps {
  class?: HTMLAttributes['class']
}

const footerProps = defineProps<CardFooterProps>()

const footerDelegatedProps = computed(() => {
  const { class: _, ...delegated } = footerProps

  return delegated
})
</script>

<template #footer>
  <div :class="cn('flex items-center p-6 pt-0', footerProps.class)" v-bind="footerDelegatedProps">
    <slot name="footer" />
  </div>
</template>