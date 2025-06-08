# Par - Parallel Claude Code Runner

Par is a Go CLI tool that executes Claude Code CLI in parallel across multiple Git worktrees.

## Architecture

The par CLI is built with Go and uses the Cobra framework for command-line interface. It follows a modular architecture with clear separation of concerns:

### Core Components

- **Command Layer** (`cmd/`): Cobra-based CLI commands (add, run, list, clean)
- **Configuration** (`internal/config/`): YAML-based configuration management with Viper
- **Prompt Management** (`internal/prompts/`): Storage and templating system for reusable prompts
- **Worktree Discovery** (`internal/worktree/`): Git worktree discovery and validation using go-git
- **Parallel Execution** (`internal/executor/`): Worker pool pattern for concurrent Claude Code execution
- **Terminal Integration** (`internal/terminal/`): Ghostty terminal support for interactive sessions
- **Results Management** (`internal/results/`): Result aggregation and reporting system

## Key Features

- **Parallel Execution**: Run Claude Code across multiple Git worktrees simultaneously
- **Prompt Templates**: Go template system with variable substitution for dynamic prompts
- **Worktree Discovery**: Automatic discovery and validation of Git repositories
- **Configuration Management**: YAML configuration with sensible defaults
- **Terminal Integration**: Optional Ghostty terminal windows for interactive sessions
- **Result Reporting**: Comprehensive result collection and reporting (console, JSON)
- **Smart Cleanup**: Automatic cleanup of temporary worktrees and failed runs
- **Cross-platform Support**: Works on Linux, macOS, and Windows

## Commands

### Primary Commands

```bash
# Add a new prompt to the library
par add [--name <name>] [--file <file>] [--template]

# Run a prompt across multiple worktrees
par run <prompt-name> [options]

# List available prompts and discovered worktrees
par list [prompts|worktrees]

# Clean up temporary files and failed runs
par clean [--all] [--failed] [-f]
```

### Run Command Options

```bash
-j, --jobs <n>              # Number of parallel jobs (default: 3)
-t, --timeout <duration>    # Timeout per job work stage (default: 60min)
--dry-run                   # Show what would be executed
--term                      # Open each job in separate terminal window (default: true)
--terminal-output           # Show real-time terminal output
-b, --branch <branch>       # Base branch for creating worktrees (default: main)
--plan                      # Enable planning phase before execution
```

## Usage Examples

```bash
# Add a new prompt interactively
par add --name "refactor-errors" --description "Refactor error handling patterns"

# Add a prompt from a file
par add --name "optimize-performance" --file ./prompts/optimize.txt

# Create a template prompt
par add --name "add-feature" --template --description "Add new feature template"

# Run prompt across discovered worktrees (default 3 parallel jobs)
par run refactor-errors

# Run with custom parallel job count and timeout
par run refactor-errors --jobs 5 --timeout 30m

# Run in dry-run mode to see what would be executed
par run refactor-errors --dry-run

# Run with terminal integration disabled
par run refactor-errors --term=false

# List all prompts and worktrees
par list

# List only prompts
par list prompts

# List only worktrees
par list worktrees

# Clean up old temporary files
par clean

# Clean up all temporary files
par clean --all

# Force clean without confirmation
par clean --all -f
```

## Configuration

Par uses a YAML configuration file located at `~/.config/par/config.yaml`:

```yaml
# Default settings
defaults:
  jobs: 3
  timeout: "60m"
  output_dir: "~/.local/share/par/results"

# Claude Code CLI settings
claude:
  binary_path: "claude-code"
  default_args: ["--dangerously-skip-permissions"]

# Terminal integration settings
terminal:
  use_ghostty: true
  wait_after_command: true
  new_window_per_job: true
  show_real_time_output: false

# Worktree discovery settings
worktrees:
  search_paths:
    - "~/projects"
    - "~/work"
  exclude_patterns:
    - "*/node_modules/*"
    - "*/.git/*"
    - "*/target/*"

# Prompt storage settings
prompts:
  storage_dir: "~/.local/share/par/prompts"
  template_engine: "go"
```

## Template System

Par supports Go template syntax for dynamic prompts. Template variables available:

- `{{.ProjectName}}` - Name of the project
- `{{.TaskName}}` - Name of the task/prompt
- `{{.Description}}` - Task description
- `{{.BranchName}}` - Git branch name
- `{{.WorktreePath}}` - Path to worktree
- `{{.Instructions}}` - Specific instructions
- `{{.ExpectedOutcome}}` - Expected outcome

### Template Functions

- `{{upper .ProjectName}}` - Convert to uppercase
- `{{lower .BranchName}}` - Convert to lowercase
- `{{title .TaskName}}` - Convert to title case
- `{{default "fallback" .Optional}}` - Provide default value

### Example Template

```markdown
# {{.ProjectName}} - {{.TaskName}}

## Task Description
{{.Description}}

## Context
Project: {{.ProjectName}}
Branch: {{.BranchName}}
Worktree: {{.WorktreePath}}

## Instructions
{{.Instructions}}

## Expected Outcome
{{.ExpectedOutcome}}
```

## Directory Structure

```
par/
├── main.go                         # CLI entry point
├── go.mod                          # Go module dependencies
├── cmd/                            # Cobra CLI commands
│   ├── root.go                     # Root command and config
│   ├── add.go                      # Add prompt command
│   ├── run.go                      # Run execution command
│   ├── list.go                     # List prompts/worktrees
│   └── clean.go                    # Cleanup command
└── internal/                       # Internal packages
    ├── config/
    │   └── config.go               # Configuration management
    ├── prompts/
    │   ├── manager.go              # Prompt storage and retrieval
    │   └── template.go             # Template processing
    ├── worktree/
    │   ├── discovery.go            # Git worktree discovery
    │   ├── manager.go              # Worktree operations
    │   ├── validator.go            # Worktree validation
    │   └── types.go                # Type definitions
    ├── executor/
    │   ├── job.go                  # Job definition and management
    │   ├── pool.go                 # Worker pool for parallel execution
    │   └── claude.go               # Claude Code CLI interface
    ├── terminal/
    │   ├── manager.go              # Terminal session management
    │   └── ghostty.go              # Ghostty terminal integration
    └── results/
        └── manager.go              # Result aggregation and storage
```

## Implementation Details

### Execution Flow

1. **Discovery Phase**: Scan configured paths for Git worktrees
2. **Validation Phase**: Filter valid worktrees based on criteria
3. **Job Creation**: Create parallel jobs for each worktree
4. **Execution Phase**: Run Claude Code CLI in worker pool
5. **Result Collection**: Aggregate results and generate reports
6. **Cleanup Phase**: Clean up temporary resources

### Error Handling

- Graceful degradation for problematic worktrees
- Automatic retry with exponential backoff
- Comprehensive error reporting and logging
- Timeout handling for long-running operations

### Security Considerations

- Sandbox execution environments
- Secure handling of Git credentials
- Rate limiting to respect Claude API limits
- Audit logging of all operations

## Dependencies

- **github.com/spf13/cobra**: Command-line interface framework
- **github.com/spf13/viper**: Configuration management
- **github.com/go-git/go-git/v5**: Git operations
- **github.com/google/uuid**: Unique identifiers
- **gopkg.in/yaml.v3**: YAML parsing

## Building and Installation

```bash
# Build from source
go build -o par .

# Install via Nix (in dotfiles)
# The program is automatically available when the par module is enabled
```

## Testing

```bash
# Run tests
go test ./...

# Run tests with coverage
go test -cover ./...

# Run specific package tests
go test ./internal/worktree
```