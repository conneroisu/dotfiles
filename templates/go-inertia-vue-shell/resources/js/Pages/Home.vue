<template>
  <Layout :title="title">
    <div class="container max-w-4xl mx-auto">
      <div class="rounded-xl border bg-card text-card-foreground shadow">
        <div class="flex flex-col space-y-1.5 p-6">
          <div class="font-semibold leading-none tracking-tight text-4xl">{{ title }}</div>
          <div class="text-sm text-muted-foreground text-lg">{{ message }}</div>
        </div>
        <div class="p-6 pt-0">
          <div class="flex gap-4">
            <Button as="a" href="/about">About</Button>
            <Button variant="outline" as="a" href="/contact">Contact</Button>
          </div>
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
  message: String,
});
</script>