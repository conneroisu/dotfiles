import { tanstackConfig } from "@tanstack/eslint-config";
import pluginQuery from "@tanstack/eslint-plugin-query";
import pluginReact from "eslint-plugin-react";
import pluginReactHooks from "eslint-plugin-react-hooks";
// @ts-expect-error - no types available
import pluginImportX from "eslint-plugin-import-x";

export default [
  ...tanstackConfig,
  {
    ignores: [
      ".nitro/**",
      ".output/**",
      ".tanstack/**",
      "dist/**",
      "build/**",
      "node_modules/**",
      "*.config.js",
      "*.config.ts",
      "better-auth_migrations/**",
      "test-results/**",
      "playwright-theme-test.js",
    ],
  },
  {
    files: ["**/*.{js,jsx,ts,tsx}"],
    plugins: {
      "@tanstack/query": pluginQuery,
      react: pluginReact,
      "react-hooks": pluginReactHooks,
      "import-x": pluginImportX,
    },
    rules: {
      // TanStack Query rules - strict enforcement
      "@tanstack/query/exhaustive-deps": "error",
      "@tanstack/query/no-rest-destructuring": "error",
      "@tanstack/query/stable-query-client": "error",
      "@tanstack/query/no-unstable-deps": "error",
      "@tanstack/query/infinite-query-property-order": "error",
      "@tanstack/query/no-void-query-fn": "error",

      // TypeScript strict rules
      "@typescript-eslint/no-unused-vars": "error",
      "@typescript-eslint/no-explicit-any": "error",
      "@typescript-eslint/prefer-nullish-coalescing": "error",
      "@typescript-eslint/prefer-optional-chain": "error",
      "@typescript-eslint/no-non-null-assertion": "error",
      "@typescript-eslint/no-unnecessary-type-assertion": "error",

      // Better Auth / Authentication security rules
      "no-console": ["warn", { allow: ["warn", "error"] }],
      "no-debugger": "error",

      // React/TanStack Router specific rules
      "react-hooks/exhaustive-deps": "error",
      "react-hooks/rules-of-hooks": "error",
      "react/jsx-uses-react": "error", // React 17+ automatic runtime
      "react/react-in-jsx-scope": "off", // React 17+ automatic runtime

      // General code quality
      "prefer-const": "error",
      "no-var": "error",
      eqeqeq: ["error", "always"],
      curly: ["error", "all"],
      "no-eval": "error",
      "no-implied-eval": "error",

      // Import organization - simplified to avoid conflicts
      "import-x/no-duplicates": "error",
      "import-x/first": "error",
    },
    settings: {
      react: {
        version: "detect",
      },
      "import-x/resolver": {
        typescript: {
          alwaysTryTypes: true,
          project: "./tsconfig.json",
        },
        node: {
          extensions: [".js", ".jsx", ".ts", ".tsx"],
        },
      },
    },
  },
  {
    // Specific rules for auth-related files
    files: ["**/auth*.{ts,tsx}", "**/lib/auth*.{ts,tsx}"],
    rules: {
      "@typescript-eslint/no-explicit-any": "error",
      "no-console": "error",
    },
  },
  {
    // Server-side specific rules
    files: ["**/api/**/*.{ts,tsx}", "**/server/**/*.{ts,tsx}"],
    rules: {
      "no-console": ["error", { allow: ["error"] }],
      "@typescript-eslint/no-explicit-any": "error",
    },
  },
];
