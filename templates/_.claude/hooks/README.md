# Claude Code Hook System

A TypeScript-based hook system for Claude Code that provides extensible event handling for various development workflows.

## Features

- **Type-safe hook implementations** with full TypeScript support
- **Modular architecture** with pluggable hook handlers
- **Security validation** for file access and command execution
- **Comprehensive logging** with structured JSON output
- **Cross-platform compatibility** using Bun runtime

## Available Hooks

- `notification` - Handle system notifications
- `pre_tool_use` - Execute before tool usage with security validation
- `post_tool_use` - Execute after tool completion with logging
- `user_prompt_submit` - Process user input submissions
- `stop` - Handle session termination with transcript logging
- `subagent_stop` - Handle subagent termination events

## Installation

Install dependencies using Bun:

```bash
bun install
```

## Usage

### Basic Hook Execution

```bash
# Execute a specific hook
bun index.ts <hook-type>

# Examples
bun index.ts notification
bun index.ts pre_tool_use
bun index.ts stop --chat
```

### Available Commands

```bash
# Show help
bun index.ts --help

# List all available hooks
bun index.ts --list

# Execute with chat transcript (for stop hooks)
bun index.ts stop --chat
bun index.ts subagent_stop --chat
```

## Configuration

The hook system is configured through the `.claude/settings.json` file:

```json
{
  "hooks": {
    "user_prompt_submit": "cd hooks && bun index.ts user_prompt_submit",
    "pre_tool_use": "cd hooks && bun index.ts pre_tool_use",
    "post_tool_use": "cd hooks && bun index.ts post_tool_use",
    "stop": "cd hooks && bun index.ts stop --chat",
    "subagent_stop": "cd hooks && bun index.ts subagent_stop --chat"
  }
}
```

## Architecture

### Core Components

- **`index.ts`** - Main entry point and hook router
- **`types.ts`** - TypeScript interfaces and type definitions
- **`utils.ts`** - Utility functions for logging and security
- **`hooks/`** - Individual hook implementations

### Hook Structure

Each hook implements a standard interface:

```typescript
export interface HookResult {
  success: boolean;
  message?: string;
  blocked?: boolean;
  exit_code: number;
}
```

### Security Features

- **Environment file protection** - Blocks access to `.env` files
- **Command validation** - Warns about potentially dangerous operations
- **Input sanitization** - Validates all hook inputs

## Development

Built with [Bun](https://bun.sh) for fast TypeScript execution and modern JavaScript features.