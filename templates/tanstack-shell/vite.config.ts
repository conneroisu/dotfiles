import { defineConfig } from "vite";
import { tanstackStart } from "@tanstack/react-start/plugin/vite";
import viteTsConfigPaths from "vite-tsconfig-paths";
import tailwindcss from "@tailwindcss/vite";

import { wrapVinxiConfigWithSentry } from "@sentry/tanstackstart-react";

const config = defineConfig({
  plugins: [
    // this is the plugin that enables path aliases
    viteTsConfigPaths({
      projects: ["./tsconfig.json"],
    }),
    tailwindcss(),
    tanstackStart(),
  ],
  server: {
    watch: {
      // Reduce file watching overhead
      ignored: [
        "**/node_modules/**",
        "**/.git/**",
        "**/dist/**",
        "**/build/**",
        "**/.next/**",
        "**/.nuxt/**",
        "**/.output/**",
        "**/coverage/**",
        "**/tmp/**",
        "**/temp/**",
        "**/logs/**",
        "**/conn/**",
      ],
      // Use polling for better stability on some systems
      usePolling: false,
      // Reduce the interval for file watching
      interval: 1000,
    },
    // Increase memory limits
    host: "0.0.0.0",
    // Enable HMR with optimizations
    hmr: {
      overlay: true,
    },
  },
  // Optimize build performance
  optimizeDeps: {
    // Include large dependencies to avoid re-bundling
    include: [
      "react",
      "react-dom",
      "@tanstack/react-router",
      "@tanstack/react-query",
      "@tanstack/react-start",
      "hoist-non-react-statics",
    ],
    // Exclude problematic dependencies
    exclude: ["@sentry/tanstackstart-react"],
  },
  // Configure esbuild for better performance
  esbuild: {
    // Reduce memory usage
    logOverride: {
      "this-is-undefined-in-esm": "silent",
      "commonjs-variable-in-esm": "silent",
    },
  },
  // Handle SSR specific configurations
  ssr: {
    noExternal: ["hoist-non-react-statics"],
  },
});

export default wrapVinxiConfigWithSentry(config, {
  org: process.env.VITE_SENTRY_ORG,
  project: process.env.VITE_SENTRY_PROJECT,
  authToken: process.env.SENTRY_AUTH_TOKEN,
  // Only print logs for uploading source maps in CI
  // Set to `true` to suppress logs
  silent: !process.env.CI,
});
