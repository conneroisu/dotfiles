import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'
import tsconfigPaths from 'vite-tsconfig-paths'
import { resolve } from 'path'

export default defineConfig({
  plugins: [react(), tsconfigPaths()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./test/setup.ts'],
    include: ['**/*.test.{ts,tsx}', '**/*.spec.{ts,tsx}'],
    exclude: ['**/node_modules/**', '**/dist/**', '**/.output/**'],
    browser: {
      enabled: false, // Set to true to run tests in browser by default
      name: 'chromium',
      provider: 'playwright',
      providerOptions: {
        launch: {
          devtools: false,
        },
      },
    },
  },
  resolve: {
    alias: {
      '~': resolve(__dirname, './app'),
    },
  },
})