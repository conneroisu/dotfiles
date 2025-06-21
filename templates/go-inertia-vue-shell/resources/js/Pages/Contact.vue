<template>
  <Layout :title="title">
    <div class="container max-w-4xl mx-auto">
      <div class="rounded-xl border bg-card text-card-foreground shadow">
        <div class="flex flex-col space-y-1.5 p-6">
          <div class="font-semibold leading-none tracking-tight text-3xl">{{ title }}</div>
        </div>
        <div class="p-6 pt-0 space-y-6">
          <form @submit.prevent="submit" class="space-y-4">
            <div class="space-y-2">
              <label for="name" class="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70">Name:</label>
              <Input
                id="name"
                v-model="form.name"
                type="text"
                required
              />
            </div>
            <div class="space-y-2">
              <label for="email" class="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70">Email:</label>
              <Input
                id="email"
                v-model="form.email"
                type="email"
                required
              />
            </div>
            <div class="space-y-2">
              <label for="message" class="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70">Message:</label>
              <Textarea
                id="message"
                v-model="form.message"
                rows="5"
                required
              />
            </div>
            <div class="flex gap-4">
              <Button type="submit" :disabled="form.processing">
                {{ form.processing ? 'Sending...' : 'Send Message' }}
              </Button>
              <Button variant="outline" as="a" href="/">Back to Home</Button>
            </div>
          </form>
        </div>
      </div>
    </div>
  </Layout>
</template>

<script setup>
import { useForm, Link } from '@inertiajs/vue3';
import Layout from '../Components/Layout.vue';
import Button from '../components/ui/button.vue';
import Input from '../components/ui/input.vue';
import Textarea from '../components/ui/textarea.vue';

defineProps({
  title: String,
});

const form = useForm({
  name: '',
  email: '',
  message: '',
});

function submit() {
  form.post('/contact');
}
</script>