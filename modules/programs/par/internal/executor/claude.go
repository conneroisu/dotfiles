package executor

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/config"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/worktree"
)

type ClaudeExecutor struct {
	binaryPath  string
	defaultArgs []string
}

type ClaudeExecution struct {
	JobID       string
	Worktree    *worktree.Worktree
	Prompt      string
	Timeout     time.Duration
	UseTerminal bool
}

type ClaudeResult struct {
	JobID        string
	Output       string
	ErrorOutput  string
	ExitCode     int
	Duration     time.Duration
	TimedOut     bool
	Error        error
}

func NewClaudeExecutor() *ClaudeExecutor {
	cfg := config.Get()
	return &ClaudeExecutor{
		binaryPath:  cfg.Claude.BinaryPath,
		defaultArgs: cfg.Claude.DefaultArgs,
	}
}

func (ce *ClaudeExecutor) Execute(ctx context.Context, execution *ClaudeExecution) (*ClaudeResult, error) {
	startTime := time.Now()
	
	// Create a context with timeout
	execCtx, cancel := context.WithTimeout(ctx, execution.Timeout)
	defer cancel()
	
	result := &ClaudeResult{
		JobID: execution.JobID,
	}
	
	// Prepare the command
	args := ce.buildArgs(execution)
	cmd := exec.CommandContext(execCtx, ce.binaryPath, args...)
	
	// Set working directory
	cmd.Dir = execution.Worktree.Path
	
	// Set environment variables
	cmd.Env = ce.buildEnvironment()
	
	// Prepare input (the prompt)
	cmd.Stdin = strings.NewReader(execution.Prompt)
	
	// Execute the command
	output, err := cmd.CombinedOutput()
	
	result.Duration = time.Since(startTime)
	result.Output = string(output)
	
	if err != nil {
		result.Error = err
		
		// Check if it was a timeout
		if execCtx.Err() == context.DeadlineExceeded {
			result.TimedOut = true
		}
		
		// Try to get exit code
		if exitError, ok := err.(*exec.ExitError); ok {
			result.ExitCode = exitError.ExitCode()
		} else {
			result.ExitCode = -1
		}
		
		result.ErrorOutput = fmt.Sprintf("Command failed: %v", err)
	} else {
		result.ExitCode = 0
	}
	
	return result, nil
}

func (ce *ClaudeExecutor) ExecuteWithTerminal(ctx context.Context, execution *ClaudeExecution) (*ClaudeResult, error) {
	cfg := config.Get()
	
	if !cfg.Terminal.UseGhostty {
		// Fall back to regular execution
		return ce.Execute(ctx, execution)
	}
	
	return ce.executeInGhostty(ctx, execution)
}

func (ce *ClaudeExecutor) executeInGhostty(ctx context.Context, execution *ClaudeExecution) (*ClaudeResult, error) {
	startTime := time.Now()
	
	result := &ClaudeResult{
		JobID: execution.JobID,
	}
	
	// Create a temporary script to run in the terminal
	scriptPath, err := ce.createExecutionScript(execution)
	if err != nil {
		result.Error = fmt.Errorf("failed to create execution script: %w", err)
		result.Duration = time.Since(startTime)
		return result, nil
	}
	defer os.Remove(scriptPath)
	
	// Build ghostty command
	args := ce.buildGhosttyArgs(execution, scriptPath)
	
	// Create context with timeout
	execCtx, cancel := context.WithTimeout(ctx, execution.Timeout)
	defer cancel()
	
	cmd := exec.CommandContext(execCtx, "ghostty", args...)
	cmd.Dir = execution.Worktree.Path
	
	// Execute in terminal
	output, err := cmd.CombinedOutput()
	
	result.Duration = time.Since(startTime)
	result.Output = string(output)
	
	if err != nil {
		result.Error = err
		if execCtx.Err() == context.DeadlineExceeded {
			result.TimedOut = true
		}
		if exitError, ok := err.(*exec.ExitError); ok {
			result.ExitCode = exitError.ExitCode()
		} else {
			result.ExitCode = -1
		}
		result.ErrorOutput = fmt.Sprintf("Terminal execution failed: %v", err)
	} else {
		result.ExitCode = 0
	}
	
	return result, nil
}

func (ce *ClaudeExecutor) buildArgs(execution *ClaudeExecution) []string {
	args := make([]string, len(ce.defaultArgs))
	copy(args, ce.defaultArgs)
	
	// Add directory flag
	args = append(args, "--directory", execution.Worktree.Path)
	
	return args
}

func (ce *ClaudeExecutor) buildEnvironment() []string {
	env := os.Environ()
	
	// Add any Claude-specific environment variables
	// You might want to set ANTHROPIC_API_KEY or other config here
	
	return env
}

func (ce *ClaudeExecutor) buildGhosttyArgs(execution *ClaudeExecution, scriptPath string) []string {
	cfg := config.Get()
	
	args := []string{
		"-e", fmt.Sprintf("bash %s", scriptPath),
	}
	
	if cfg.Terminal.WaitAfterCommand {
		args = append(args, "--wait-after-command=true")
	}
	
	// Set window title
	title := fmt.Sprintf("Par: %s - %s", 
		execution.Worktree.GetDisplayName(),
		execution.Worktree.Branch)
	args = append(args, "--title", title)
	
	return args
}

func (ce *ClaudeExecutor) createExecutionScript(execution *ClaudeExecution) (string, error) {
	// Create a temporary directory for scripts
	tempDir := filepath.Join(os.TempDir(), "par", "scripts")
	if err := os.MkdirAll(tempDir, 0755); err != nil {
		return "", err
	}
	
	// Create the script file
	scriptFile := filepath.Join(tempDir, fmt.Sprintf("exec-%s.sh", execution.JobID))
	
	// Prepare the script content
	scriptContent := fmt.Sprintf(`#!/bin/bash
cd "%s"

echo "Par Execution"
echo "============="
echo "Worktree: %s"
echo "Branch: %s"
echo "Job ID: %s"
echo ""

# Write prompt to temporary file
PROMPT_FILE=$(mktemp)
cat > "$PROMPT_FILE" << 'EOF'
%s
EOF

# Execute Claude Code with the prompt
echo "Executing Claude Code CLI..."
%s %s < "$PROMPT_FILE"

# Cleanup
rm -f "$PROMPT_FILE"

echo ""
echo "Execution completed. Press any key to close."
read -n 1
`, 
		execution.Worktree.Path,
		execution.Worktree.GetDisplayName(),
		execution.Worktree.Branch,
		execution.JobID,
		execution.Prompt,
		ce.binaryPath,
		strings.Join(ce.buildArgs(execution), " "))
	
	// Write the script
	if err := os.WriteFile(scriptFile, []byte(scriptContent), 0755); err != nil {
		return "", err
	}
	
	return scriptFile, nil
}

func (ce *ClaudeExecutor) ValidateClaudeCLI() error {
	// Check if the Claude CLI binary exists and is executable
	_, err := exec.LookPath(ce.binaryPath)
	if err != nil {
		return fmt.Errorf("Claude Code CLI not found in PATH: %s", ce.binaryPath)
	}
	
	// Try to run a simple version check
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	
	cmd := exec.CommandContext(ctx, ce.binaryPath, "--version")
	output, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("failed to execute Claude Code CLI: %w (output: %s)", err, string(output))
	}
	
	return nil
}

func (ce *ClaudeExecutor) GetBinaryPath() string {
	return ce.binaryPath
}