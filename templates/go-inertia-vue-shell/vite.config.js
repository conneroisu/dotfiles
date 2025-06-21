import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';

export default defineConfig({
  plugins: [vue()],
  build: {
    manifest: true,
    outDir: 'public/build',
    rollupOptions: {
      input: ['resources/js/app.js', 'resources/css/app.css'],
    },
  },
});