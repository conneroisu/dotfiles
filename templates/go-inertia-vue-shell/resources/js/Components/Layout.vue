<template>
  <div>
    <Head :title="title" />
    <div class="min-h-screen flex flex-col">
      <nav class="border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div class="container flex h-14 items-center">
          <div class="flex gap-6 items-center">
            <Link href="/" class="font-medium transition-colors hover:text-foreground/80">Home</Link>
            <Link href="/about" class="font-medium transition-colors hover:text-foreground/80">About</Link>
            <Link href="/contact" class="font-medium transition-colors hover:text-foreground/80">Contact</Link>
          </div>
        </div>
      </nav>
      <main class="flex-1 p-8">
        <slot />
      </main>
      <footer class="border-t py-6 md:py-0">
        <div class="container flex items-center justify-center md:h-16">
          <p class="text-center text-sm leading-loose text-muted-foreground">
            &copy; 2024 Inertia + Go + Vue App
          </p>
        </div>
      </footer>
    </div>
  </div>
</template>

<script setup>
import { Head, Link } from '@inertiajs/vue3';

defineProps({
  title: String,
});
</script>