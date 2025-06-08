# Par

Par is a Rust program that executes Claude Code CLI in parallel across multiple git worktrees.

## Architecture

- **Prompt Management**: Store and manage reusable prompts with template support using Tera
- **Worktree Discovery**: Automatically discover and validate git worktrees using gitoxide
- **Parallel Execution**: Run Claude Code CLI sessions across multiple targets simultaneously with tokio
- **Result Aggregation**: Collect and report results from all executions
- **Terminal Integration**: Support for Ghostty terminal windows for interactive sessions

## Key Features

- Parallel execution across multiple git worktrees
- Prompt templates with variable substitution using Tera templating
- Real-time progress monitoring with indicatif
- Comprehensive result reporting (console, JSON, HTML)
- Ghostty terminal integration for interactive sessions
- Automatic cleanup and error recovery
- Cross-platform support (Linux, macOS, Windows)

## Usage

```bash
# Add a new prompt
par add --name "refactor-errors" --description "Refactor error handling"

# Run prompt across discovered worktrees (default 3 parallel jobs)
par run refactor-errors

# Run with custom parallel job count
par run refactor-errors --jobs 5

# Run with debug logging for troubleshooting
par --log-level debug run refactor-errors

# List available prompts and worktrees
par list

# Clean up temporary files
par clean
```

## Logging and Observability

Par includes configurable logging for better observability:

- `--log-level error`: Only errors
- `--log-level warn`: Warnings and errors
- `--log-level info`: General information (default)
- `--log-level debug`: Detailed execution information
- `--log-level trace`: Very detailed tracing information

The log level can also be set via the `RUST_LOG` environment variable.

## Configuration

Par uses a YAML configuration file located at `~/.config/par/config.yaml`:

```yaml
defaults:
  jobs: 3
  timeout: "30m"
  output_dir: "~/.local/share/par/results"

claude:
  binary_path: "claude-code"
  default_args: []

terminal:
  use_ghostty: true
  wait_after_command: true
  new_window_per_job: true
  show_real_time_output: false

worktrees:
  search_paths:
    - "~/projects"
    - "~/work"
  exclude_patterns:
    - "*/node_modules/*"
    - "*/.git/*"
    - "*/target/*"

prompts:
  storage_dir: "~/.local/share/par/prompts"
  template_engine: "tera"
```

## Implementation Status

- [x] Rust CLI framework with clap
- [x] Prompt management system with Tera templates
- [x] Git worktree discovery and validation using gitoxide
- [x] Parallel job execution pool with tokio
- [x] Result aggregation and reporting
- [x] Ghostty terminal integration
- [x] Configuration management with serde
- [x] Template system with variable substitution
- [x] Error handling and recovery with thiserror
- [x] Cleanup operations

## Dependencies

- **clap**: Command-line argument parsing
- **tokio**: Async runtime for parallel execution
- **gix**: Git operations using gitoxide
- **tera**: Template engine for prompt processing
- **serde**: Serialization for configuration and results
- **chrono**: Date/time handling
- **uuid**: Unique job identifiers
- **indicatif**: Progress bars and spinners
- **tabled**: Table formatting for list commands

## Testing

Run tests with:
```bash
cargo test
```

Run with all features:
```bash
cargo test --all-features
```