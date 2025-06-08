# Par - Parallel Claude Code Runner

## Overview

`par` is a Go program that runs the Claude Code CLI across multiple Git worktree branches/directories simultaneously, applying the same initial prompt to achieve consistent goals across different codebases or branches.

## Use Cases

- **Multi-branch Development**: Apply the different code changes or improvements across multiple feature branches with the same goal/(initial prompt)
- **Planned Development**: Plan prior to changes conditionally with the `--plan` flag (occurs in parallel with worktree agents *higher cost*)
- **Smart Branching**: Use the (-b/--branch) flag to branch from a specific base branch (default: main (found in .git/config))
- **Optional Terminal Integration**: Use the `--terms` flag to open each job in a separate terminal window (`$TERM` must be set)
- **Thrifty Usage**: By default, the agent should now commit any changes made to the worktrees as a fresh agent will do that for that agent.
- **Subdir Organization**: Will automatically prepend `feat/<feature>/try-<generated-uuid>` to the worktree name to clearly identify the feature branch and parallel executed work.

## Architecture

### Core Components

1. **Prompt Manager** (`prompts/`)
   - Store and manage reusable prompts
   - Support for prompt templates with variables
   - Prompt versioning and history

2. **Worktree Manager** (`worktree/`)
   - Discover and validate Git worktrees
   - Create temporary worktrees for isolated operations
   - Cleanup and management of worktree state

3. **Job Executor** (`executor/`)
   - Parallel execution of Claude Code CLI sessions
   - Job queuing and scheduling
   - Resource management and throttling

4. **Result Aggregator** (`results/`)
   - Collect and consolidate outputs from all sessions
   - Generate summary reports
   - Handle success/failure tracking

### Directory Structure

```
par/
├── main.go                 # CLI entry point
├── cmd/
│   ├── add.go             # Add new prompts
│   ├── run.go             # Execute parallel runs
│   ├── list.go            # List prompts and worktrees
│   └── clean.go           # Cleanup operations
├── internal/
│   ├── config/
│   │   └── config.go      # Configuration management
│   ├── prompts/
│   │   ├── manager.go     # Prompt storage and retrieval
│   │   └── template.go    # Template processing
│   ├── worktree/
│   │   ├── discovery.go   # Find Git worktrees
│   │   ├── manager.go     # Worktree operations
│   │   └── validator.go   # Validate worktree state
│   ├── executor/
│   │   ├── job.go         # Job definition and execution
│   │   ├── pool.go        # Worker pool management
│   │   └── claude.go      # Claude Code CLI interface
│   ├── terminal/
│   │   ├── ghostty.go     # Ghostty terminal integration for new windows
│   │   ├── manager.go     # Terminal session management  
│   │   └── output.go      # Terminal output handling
│   └── results/
│       ├── aggregator.go  # Collect and process results
│       ├── reporter.go    # Generate reports
│       └── storage.go     # Persist results
└── spec/
    └── par.md             # This specification
```

## Command Line Interface

### Primary Commands

```bash
# Add a new prompt to the library
par add [--name <name>] [--file <file>] [--template]

# Run a prompt across multiple worktrees
par run <prompt-name> [options]

# List available prompts and discovered worktrees
par list [prompts|worktrees]

# Clean up temporary files and failed runs
par clean [--all] [--failed]
```

### Options for `par run`

```bash
-j, --jobs <n>              # Number of parallel jobs (default: 3)
-t, --timeout <duration>    # Timeout per job work stage (default: 60min)
-o, --output <dir>          # Output directory for results
--dry-run                   # Show what would be executed
--continue-on-failure       # Continue even if some jobs fail
--template-vars <key=val>   # Template variable substitution
--ghostty                   # Open each job in separate Ghostty window
--terminal-output           # Show real-time terminal output
```

## Configuration

### Configuration File (~/.config/par/config.yaml)

```yaml
# Default settings
defaults:
  jobs: 4
  timeout: "30m"
  output_dir: "~/.local/share/par/results"
  
# Claude Code CLI settings
claude:
  binary_path: "claude-code"  # or full path
  default_args: []

# Terminal settings  
terminal:
  use_ghostty: true
  wait_after_command: true    # Keep terminal open after command exits
  new_window_per_job: true    # Open separate window for each job
  show_real_time_output: false # Show output in real-time vs buffered
  
# Worktree discovery
worktrees:
  search_paths:
    - "~/projects"
    - "~/work"
  exclude_patterns:
    - "*/node_modules/*"
    - "*/.git/*"
    - "*/target/*"
    
# Prompt storage
prompts:
  storage_dir: "~/.local/share/par/prompts"
  template_engine: "go-template"  # or "simple"
```

## Prompt Management

### Prompt Storage Format

```yaml
# ~/.local/share/par/prompts/refactor-error-handling.yaml
name: "refactor-error-handling"
description: "Refactor error handling to use structured errors"
created: "2025-06-06T10:00:00Z"
template: true
variables:
  - name: "error_type"
    description: "Type of error handling to implement"
    default: "structured"
  - name: "package_name"
    description: "Target package name"
    required: true

prompt: |
  Please refactor the error handling in the {{.package_name}} package to use {{.error_type}} errors.
  
  Requirements:
  - Create custom error types
  - Wrap errors with context
  - Ensure all errors include stack traces
  - Update tests accordingly
```

### Template System

- Support Go template syntax for variable substitution
- Built-in functions for common operations
- Validation of required variables
- Default value handling

## Execution Flow

### 1. Discovery Phase

```go
// Discover available worktrees
worktrees := discovery.FindWorktrees(config.SearchPaths, config.ExcludePatterns)

// Validate each worktree
validWorktrees := validator.FilterValid(worktrees)
```

### 2. Job Planning

```go
// Load prompt and process templates
prompt := prompts.Load(promptName)
processedPrompt := template.Process(prompt, templateVars)

// Create jobs for each target
jobs := make([]Job, len(validWorktrees))
for i, worktree := range validWorktrees {
    jobs[i] = Job{
        ID: uuid.New(),
        Worktree: worktree,
        Prompt: processedPrompt,
        Timeout: config.Timeout,
    }
}
```

### 3. Parallel Execution

```go
// Create worker pool
pool, err := executor.NewPool(config.Jobs, config)
if err != nil {
    log.Fatal(err)
}

// Execute jobs
results := pool.Execute(jobs)
```

### 4. Result Aggregation

```go
// Collect and analyze results
summary := aggregator.ProcessResults(results)

// Generate reports
reporter.GenerateReport(summary, config.OutputDir)
```

## Error Handling

### Failure Modes

1. **Worktree Issues**
   - Dirty working directory
   - Merge conflicts
   - Missing dependencies

2. **Claude Code CLI Issues**
   - Authentication failures
   - Rate limiting
   - Network connectivity

3. **Resource Constraints**
   - Memory exhaustion
   - Disk space
   - CPU throttling

### Recovery Strategies

- Automatic retry with exponential backoff
- Graceful degradation (skip problematic worktrees)
- Checkpoint/resume functionality for long-running operations
- Detailed logging for debugging

## Output and Reporting

### Result Structure

```go
type JobResult struct {
    JobID        string    `json:"job_id"`
    Worktree     string    `json:"worktree"`
    Status       Status    `json:"status"`  // Success, Failed, Timeout
    StartTime    time.Time `json:"start_time"`
    EndTime      time.Time `json:"end_time"`
    Duration     time.Duration `json:"duration"`
    Output       string    `json:"output"`
    ErrorMessage string    `json:"error_message,omitempty"`
    ExitCode     int       `json:"exit_code"`
}
```

### Report Formats

1. **Console Summary**
   ```
   Par Execution Summary
   =====================
   Total Jobs: 12
   Successful: 10
   Failed: 2
   Total Duration: 5m 23s
   
   Failed Jobs:
   - feature/auth-refactor: timeout after 30m
   - hotfix/security-patch: git working directory dirty
   ```

2. **JSON Report** (for automation)
3. **HTML Report** (for detailed analysis)

## Integration

### Terminal Integration

#### Ghostty Terminal Features

- **New Window Per Job**: Each parallel execution opens in a separate Ghostty window
- **Wait After Command**: Terminal stays open after Claude Code execution finishes (useful for reviewing results)
- **Real-time Output**: Option to stream output in real-time or buffer until completion
- **Window Management**: Automatic window naming based on worktree/job information

#### Terminal Command Execution

```go
// Example Ghostty command execution
ghosttyCmd := []string{
    "ghostty",
    "-e", fmt.Sprintf("claude-code --directory=%s", worktree.Path),
    "--wait-after-command=true",
    "--title=" + fmt.Sprintf("Par: %s", worktree.Name),
}
```

### Git Integration

- Automatic stashing of uncommitted changes
- Branch validation before execution
- Post-execution cleanup
- Integration with Git hooks

### CI/CD Integration

- Exit codes for automation
- Machine-readable output formats
- Docker container support
- GitHub Actions workflow examples

## Security Considerations

- Prompt injection prevention
- Sandbox execution environments
- Rate limiting to respect Claude API limits
- Audit logging of all operations
- Secure storage of API credentials

## Future Enhancements

1. **Web Interface**
   - Browser-based prompt management
   - Real-time job monitoring
   - Visual result analysis

2. **Plugin System**
   - Custom post-processing hooks
   - Third-party integrations
   - Custom worktree discovery

3. **Advanced Scheduling**
   - Cron-like scheduling
   - Dependency-based execution
   - Resource-aware scheduling

4. **Collaboration Features**
   - Shared prompt libraries
   - Team result sharing
   - Permission management

## Implementation Phases

### Phase 1: Core Functionality
- Basic CLI structure
- Simple prompt storage
- Sequential execution
- Basic reporting

### Phase 2: Parallel Execution
- Worker pool implementation
- Concurrent job execution
- Error handling and recovery
- Enhanced reporting

### Phase 3: Advanced Features
- Template system
- Configuration management
- Git integration
- Result persistence
- Ghostty terminal integration
- Real-time output streaming

## Terminal Integration Details

### Ghostty Configuration

The `par` tool leverages Ghostty's command execution capabilities to provide an enhanced user experience:

#### Window Management
- Each parallel job opens in its own Ghostty window
- Windows are automatically titled with worktree/branch information
- Support for custom window positioning and sizing
- Automatic cleanup of windows after job completion (configurable)

#### Command Execution
```go
type GhosttyConfig struct {
    WaitAfterCommand bool   `yaml:"wait_after_command"`
    NewWindowPerJob  bool   `yaml:"new_window_per_job"`
    WindowTitle      string `yaml:"window_title_template"`
    RealTimeOutput   bool   `yaml:"real_time_output"`
}

// Execute job in Ghostty window
func (g *GhosttyExecutor) ExecuteJob(job *Job) error {
    cmd := []string{
        "ghostty",
        "-e", fmt.Sprintf("cd %s && claude-code", job.Worktree.Path),
    }
    
    if g.config.WaitAfterCommand {
        cmd = append(cmd, "--wait-after-command=true")
    }
    
    if g.config.WindowTitle != "" {
        title := g.renderTitle(job, g.config.WindowTitle)
        cmd = append(cmd, "--title="+title)
    }
    
    return exec.Command(cmd[0], cmd[1:]...).Run()
}
```

#### Benefits
- **Visual Separation**: Each worktree operation is clearly separated
- **Parallel Monitoring**: Users can monitor multiple operations simultaneously
- **Interactive Debugging**: Ability to interact with Claude Code sessions if needed
- **Result Persistence**: Terminal windows can remain open for result review
