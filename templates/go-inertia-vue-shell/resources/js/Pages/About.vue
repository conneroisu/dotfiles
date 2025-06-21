<template>
  <Layout :title="title">
    <div class="container max-w-4xl mx-auto">
      <div class="rounded-xl border bg-card text-card-foreground shadow">
        <div class="flex flex-col space-y-1.5 p-6">
          <div class="font-semibold leading-none tracking-tight text-3xl">{{ title }}</div>
        </div>
        <div class="p-6 pt-0 space-y-4">
          <p class="text-muted-foreground">{{ content }}</p>
          <Button variant="outline" as="a" href="/">Back to Home</Button>
        </div>
      </div>
    </div>
  </Layout>
</template>

<script setup>
import { Link } from '@inertiajs/vue3';
import Layout from '../Components/Layout.vue';
import Button from '../components/ui/button.vue';

defineProps({
  title: String,
  content: String,
});
</script>