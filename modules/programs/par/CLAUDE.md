# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Par is a Go CLI tool that runs Claude Code CLI across multiple Git worktree branches/directories simultaneously, applying the same initial prompt to achieve consistent goals across different codebases or branches. It's designed for parallel automation of coding tasks across multiple project directories.

## Common Commands

### Development
```bash
go build -o par .                    # Build the binary
go run . --help                      # Run with help
go test ./...                        # Run all tests
go mod tidy                          # Clean up dependencies
```

### Using Par
```bash
# Add a new prompt to library
./par add --name "fix-bugs" --file prompt.txt

# List available prompts
./par list

# Run a prompt across worktrees (dry run first)
./par run my-prompt --dry-run

# Execute with custom options
./par run my-prompt --jobs 8 --timeout 45m --continue-on-failure

# Run on specific directories instead of discovered worktrees
./par run my-prompt --directories /path/to/proj1,/path/to/proj2

# Use template prompts with variables
./par add --name "refactor" --template
./par run refactor --template-vars "function=calculateTotal,newName=computeSum"
```

## Architecture

### Core Components

**Command Structure (`cmd/`)**:
- `root.go` - Main CLI setup using Cobra framework
- `add.go` - Prompt management (add prompts from stdin/file, template support)  
- `run.go` - Core execution engine (parallel job runner)
- `list.go` - Prompt listing and discovery
- `clean.go` - Cleanup operations

**Execution Engine (`internal/executor/`)**:
- `pool.go` - Job pool for parallel execution across worktrees
- `job.go` - Individual job definitions and state management
- `claude.go` - Claude Code CLI integration and command building

**Prompt System (`internal/prompts/`)**:
- `manager.go` - Prompt storage/retrieval (YAML-based filesystem storage)
- `template.go` - Go template processing with variable substitution

**Worktree Discovery (`internal/worktree/`)**:
- `discovery.go` - Automatic Git worktree detection across search paths
- `manager.go` - Worktree filtering and pattern matching
- `validator.go` - Worktree validation and health checks

**Configuration (`internal/config/`)**:
- `config.go` - YAML-based configuration with sensible defaults
- Search paths, exclusion patterns, Claude CLI settings, terminal integration

**Results Processing (`internal/results/`)**:
- `aggregator.go` - Job result collection and summarization
- `reporter.go` - Console and file output formatting
- `storage.go` - Session-based result persistence

### Execution Flow

1. **Prompt Loading**: Load from `~/.local/share/par/prompts/` with template variable substitution
2. **Worktree Discovery**: Scan configured search paths, apply exclusion patterns, validate Git repositories
3. **Job Creation**: Create parallel jobs for each valid worktree with timeout and context
4. **Parallel Execution**: Execute Claude Code CLI via job pool with configurable concurrency
5. **Result Aggregation**: Collect outputs, errors, timing data across all jobs
6. **Reporting**: Generate console reports and save detailed results to `~/.local/share/par/results/`

### Configuration System

Par uses a hierarchical configuration approach:
- Default config embedded in code for zero-setup experience
- User config at `~/.config/par/config.yaml` for customization
- Runtime flags override config file settings

Key configuration areas:
- **Worktree Discovery**: Search paths and exclusion patterns
- **Claude Integration**: Binary path and default arguments  
- **Terminal Integration**: Ghostty window management for job visualization
- **Execution Tuning**: Default job counts, timeouts, output directories

### Prompt Template System

Supports Go template syntax with variable substitution:
- Template prompts stored with variable definitions (name, description, default, required)
- Runtime variable substitution via `--template-vars key=value` flags
- Enables reusable, parameterized automation prompts

### Dependencies

- **Cobra**: CLI framework for commands and flags
- **YAML v3**: Configuration and prompt storage format
- **UUID**: Session identification for result tracking
- **Claude Code CLI**: Must be available in PATH or configured binary path
- **ANTHROPIC_API_KEY**: Required environment variable for Claude API access