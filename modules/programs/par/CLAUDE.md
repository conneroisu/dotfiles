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
- `manager.go` - Worktree filtering, pattern matching, and state management
- `validator.go` - Comprehensive worktree validation (Git status, Claude CLI, conflicts)

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

#### Default Configuration Structure

**Default Search Paths**:
- `~/projects` (maps to user's project directory)
- `~/work` (maps to user's work directory)

**Claude CLI Settings**:
- Binary path: `"claude-code"` (expects CLI in PATH)
- Default arguments: empty array
- Validation: Checks `--version` flag and `ANTHROPIC_API_KEY` environment variable

**Worktree Validation**:
- Path existence and Git repository validation
- Working directory cleanliness (uncommitted changes detection)
- Merge conflict detection
- Claude CLI availability check

#### Configuration Customization Examples

**Custom Search Paths**:
```yaml
worktrees:
  search_paths:
    - "/home/user/Documents/001Repos"
    - "/home/user/Documents/002Orgs"
```

**Custom Claude Binary** (for non-standard installations like bun):
```yaml
claude:
  binary_path: "/home/user/.bun/bin/claude"
```

**Exclusion Patterns**:
```yaml
worktrees:
  exclude_patterns:
    - "*/node_modules/*"
    - "*/.git/*"
    - "*/target/*"
    - "*/build/*"
```

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

## Troubleshooting

### Common Issues

**Claude CLI Not Found**:
- Error: `claude-code CLI not available`
- Solutions:
  1. Install Claude Code CLI: `npm install -g @anthropic-ai/claude-code` or `bun install -g @anthropic-ai/claude-code`
  2. Configure custom binary path in `~/.config/par/config.yaml`:
     ```yaml
     claude:
       binary_path: "/path/to/claude-code"
     ```
  3. For bun installations, use: `binary_path: "/home/user/.bun/bin/claude"`

**No Worktrees Found**:
- Error: `No worktrees found in search paths`
- Solutions:
  1. Check if search paths exist and contain Git repositories
  2. Customize search paths in configuration:
     ```yaml
     worktrees:
       search_paths:
         - "/actual/path/to/repos"
     ```
  3. Use explicit directories: `./par run prompt --directories /path/to/repo1,/path/to/repo2`

**Invalid Worktrees**:
- Common validation failures:
  - `has uncommitted changes`: Commit or stash changes before running
  - `not a Git repository`: Ensure directory is a valid Git repository
  - `has unresolved merge conflicts`: Resolve conflicts before execution
  - `path does not exist`: Verify search paths are correct

**API Key Issues**:
- Error: `ANTHROPIC_API_KEY environment variable not set`
- Solution: Set environment variable: `export ANTHROPIC_API_KEY="your-api-key"`

## Development Notes

### Module Architecture

The validator system is designed with dependency injection:
- `Validator` requires `*config.Config` to access Claude binary path settings
- `Manager` creates validators with proper configuration
- All validation logic respects user configuration overrides

### Build Process

```bash
# Standard Go build in project directory
go build -o par .

# Build from outside directory
go build -C /path/to/par -o par .
```

### Testing Configuration

Create a minimal test configuration:
```yaml
# ~/.config/par/config.yaml
worktrees:
  search_paths:
    - "/path/to/test/repos"
claude:
  binary_path: "claude"  # or custom path
```