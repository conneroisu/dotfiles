import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  build: {
    manifest: true,
    outDir: 'public/build',
    rollupOptions: {
      input: ['resources/js/app.jsx', 'resources/css/app.css'],
    },
  },
});