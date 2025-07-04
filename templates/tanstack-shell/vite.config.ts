import { defineConfig } from 'vite'
import { tanstackStart } from '@tanstack/react-start/plugin/vite'
import tsConfigPaths from 'vite-tsconfig-paths'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [
    tsConfigPaths(),
    tanstackStart(),
    tailwindcss(),
  ],
  server: {
    port: 3000,
    host: true,
  },
  build: {
    target: 'node18',
  },
})