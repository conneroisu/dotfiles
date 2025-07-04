import { defineConfig } from '@tanstack/start/config'

export default defineConfig({
  server: {
    preset: 'node',
  },
  react: {
    babel: {
      plugins: [],
    },
  },
})