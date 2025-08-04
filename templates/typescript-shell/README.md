# TypeScript Development Shell Template

A comprehensive TypeScript development environment with modern tooling for building high-quality TypeScript applications.

## Features

### Core TypeScript Tooling
- **TypeScript Compiler** - Latest TypeScript with ES2022+ support
- **tsx** - Fast TypeScript execution and development server
- **Node.js** - JavaScript runtime with TypeScript support

### Multiple Linting Options
- **ESLint** - Configurable JavaScript/TypeScript linter
- **oxlint** - Fast Rust-based linter for performance
- **Biome** - All-in-one formatter and linter

### Language Servers (LSP)
- **TypeScript Language Server** - Rich IDE integration
- **Tailwind CSS Language Server** - CSS framework support
- **HTML/CSS/JSON LSPs** - Complete web development support
- **YAML Language Server** - Configuration file support

### Package Managers
- **npm** - Node Package Manager
- **yarn** - Alternative package manager
- **pnpm** - Fast, disk space efficient
- **bun** - Fast all-in-one JavaScript runtime

### Development Tools
- **Prettier** - Code formatter
- **Vitest** - Modern testing framework
- **Playwright** - E2E testing capabilities
- **Tailwind CSS** - Utility-first CSS framework
- **Vite/Webpack/Parcel** - Build tools

## Quick Start

```bash
# Create new project from template
nix flake init -t github:conneroisu/dotfiles#typescript-shell

# Enter development shell
nix develop

# Initialize TypeScript project
init-ts
init-package

# Start development
dev
```

## Available Commands

### Project Setup
- `init-ts` - Initialize TypeScript project with modern config
- `init-package` - Initialize package.json
- `tx` - Edit tsconfig.json
- `px` - Edit package.json

### Development
- `dev` - Start development server with tsx watch
- `typecheck` - Run TypeScript type checking
- `build` - Build TypeScript project
- `test` - Run tests with Vitest

### Code Quality
- `lint-eslint` - Lint with ESLint
- `lint-oxlint` - Lint with oxlint (fast)
- `lint-biome` - Lint with Biome
- `format-prettier` - Format with Prettier
- `format-biome` - Format with Biome

### Utilities
- `clean` - Clean build artifacts
- `dx` - Edit flake.nix

## TypeScript Configuration

The template initializes TypeScript with modern settings:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "noEmit": true,
    "strict": true
  }
}
```

## Linting Strategy

Choose the linting approach that fits your project:

### ESLint (Traditional)
- Most configurable
- Extensive plugin ecosystem
- Good TypeScript integration

### oxlint (Performance)
- Rust-based for speed
- Minimal configuration
- Fast feedback loops

### Biome (All-in-one)
- Combined linting and formatting
- Fast Rust implementation
- Simple configuration

## Testing Setup

Vitest is included for modern TypeScript testing:

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    environment: 'node',
    globals: true,
  },
})
```

## Editor Integration

The included language servers provide rich IDE features:

- **TypeScript LSP** - Type checking, autocomplete, refactoring
- **Tailwind CSS LSP** - Class name completion and validation
- **ESLint LSP** - Real-time linting feedback

## Package Management

Multiple package managers are available:

```bash
# npm (traditional)
npm install package-name

# yarn (alternative)
yarn add package-name

# pnpm (efficient)
pnpm add package-name

# bun (fast)
bun add package-name
```

## Build Tools

Choose your preferred build tool:

- **Vite** - Fast development and building
- **Webpack** - Mature bundler with extensive plugins
- **Parcel** - Zero-configuration build tool

## Platform Support

- ✅ x86_64-linux (Intel/AMD Linux)
- ✅ aarch64-linux (ARM64 Linux)
- ✅ x86_64-darwin (Intel macOS)
- ✅ aarch64-darwin (Apple Silicon macOS)

## Example Project Structure

```
my-typescript-project/
├── src/
│   ├── index.ts          # Main entry point
│   ├── types/            # Type definitions
│   └── utils/            # Utility functions
├── tests/
│   └── index.test.ts     # Vitest tests
├── package.json          # Dependencies
├── tsconfig.json         # TypeScript config
├── vitest.config.ts      # Test configuration
├── .eslintrc.js          # ESLint config (optional)
├── biome.json            # Biome config (optional)
└── flake.nix             # Nix development environment
```

## Tips

1. **Start Simple**: Use `init-ts && init-package` to set up basics
2. **Choose One Linter**: Pick ESLint, oxlint, or Biome - don't mix
3. **Use tsx for Development**: Fast TypeScript execution without compilation
4. **Type-only Imports**: Use `import type` for type-only imports
5. **Strict Mode**: The template enables strict TypeScript checking

## Troubleshooting

### Common Issues

**"Module not found"**: Check your tsconfig.json moduleResolution setting
**"TypeScript errors in IDE"**: Ensure TypeScript LSP is running
**"Slow linting"**: Try oxlint for faster feedback
**"Build errors"**: Run `typecheck` to see TypeScript issues

### Performance Tips

- Use `oxlint` for faster linting
- Use `bun` for faster package installation
- Use `tsx` instead of `tsc && node` for development
- Enable TypeScript incremental compilation