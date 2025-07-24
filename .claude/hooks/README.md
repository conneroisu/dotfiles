# Claude Code Hooks - TypeScript Implementation

A robust TypeScript-based hook system for Claude Code that provides security validation, logging, and extensible functionality.

## 🚀 Quick Start

### Installation

```bash
bun install
```

### Usage

```bash
# Run a specific hook
bun index.ts <hook-type> [options]

# Available hooks: notification, pre_tool_use, post_tool_use, user_prompt_submit, stop, subagent_stop
bun index.ts notification
bun index.ts stop --chat
```

### Help

```bash
# Show help
bun index.ts --help

# List available hooks
bun index.ts --list
```

## 🧪 Testing

```bash
# Run all tests
bun test

# Run tests in watch mode
bun test:watch

# Run tests with coverage
bun test:coverage

# Lint code
bun lint
```

## 🏗️ Architecture

The hooks system is built with:

- **TypeScript** for type safety and better developer experience
- **Modular design** with separate hook implementations
- **Security-first approach** with input validation and dangerous command detection
- **Comprehensive logging** for audit trails and debugging
- **Error handling** with graceful degradation

### Hook Types

- `notification` - Logs notification events
- `pre_tool_use` - Validates tool usage before execution with security checks
- `post_tool_use` - Logs tool execution events after completion
- `user_prompt_submit` - Logs user prompt submissions
- `stop` - Handles session completion with linting and TTS announcements
- `subagent_stop` - Handles subagent completion events

## 🔒 Security Features

- **Environment file protection** - Blocks access to `.env` files
- **Dangerous command detection** - Identifies potentially harmful commands
- **Path traversal prevention** - Validates file paths
- **Shell injection protection** - Properly escapes shell arguments
- **Input validation** - Validates all inputs before processing

## 📁 Project Structure

```
.claude/hooks/
├── hooks/           # Individual hook implementations
├── tests/           # Test suite
│   ├── unit/        # Unit tests
│   └── integration/ # Integration tests
├── index.ts         # Main entry point and router
├── types.ts         # TypeScript type definitions
├── utils.ts         # Utility functions and security validators
└── package.json     # Project configuration
```

This project was created using `bun init` in bun v1.2.18. [Bun](https://bun.sh) is a fast all-in-one JavaScript runtime.
