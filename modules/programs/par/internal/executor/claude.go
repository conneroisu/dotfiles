package executor

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"time"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/config"
)

// ClaudeExecutor handles execution of Claude Code CLI
type ClaudeExecutor struct {
	config *config.Config
}

// NewClaudeExecutor creates a new Claude Code executor
func NewClaudeExecutor(config *config.Config) *ClaudeExecutor {
	return &ClaudeExecutor{
		config: config,
	}
}

// ExecuteJob executes a job using Claude Code CLI
func (e *ClaudeExecutor) ExecuteJob(ctx context.Context, job *Job) error {
	job.Status = StatusRunning
	job.StartTime = time.Now()
	
	// Prepare the command
	cmd := e.buildCommand(job)
	cmd.Dir = job.Worktree.Path
	
	// Create a timeout context
	timeoutCtx, cancel := context.WithTimeout(ctx, job.Timeout)
	defer cancel()
	
	// Execute the command
	output, err := e.runCommand(timeoutCtx, cmd, job.Prompt)
	
	job.EndTime = time.Now()
	job.Output = output
	
	if err != nil {
		job.Error = err.Error()
		
		// Check if it was a timeout
		if timeoutCtx.Err() == context.DeadlineExceeded {
			job.Status = StatusTimeout
		} else {
			job.Status = StatusFailed
		}
		
		// Try to get exit code
		if exitError, ok := err.(*exec.ExitError); ok {
			job.ExitCode = exitError.ExitCode()
		} else {
			job.ExitCode = 1
		}
		
		return err
	}
	
	job.Status = StatusSuccess
	job.ExitCode = 0
	
	return nil
}

// buildCommand builds the Claude Code CLI command
func (e *ClaudeExecutor) buildCommand(job *Job) *exec.Cmd {
	args := []string{
		"--print", // Use non-interactive mode
	}
	
	// Add any default arguments from config
	args = append(args, e.config.Claude.DefaultArgs...)
	
	// Create the command
	cmd := exec.Command(e.config.Claude.BinaryPath, args...)
	
	return cmd
}

// runCommand runs the command with the given prompt as stdin
func (e *ClaudeExecutor) runCommand(ctx context.Context, cmd *exec.Cmd, prompt string) (string, error) {
	// Set up stdin with the prompt
	cmd.Stdin = strings.NewReader(prompt)
	
	// Capture output
	output, err := cmd.CombinedOutput()
	
	// Check for context cancellation
	if ctx.Err() != nil {
		return string(output), ctx.Err()
	}
	
	return string(output), err
}

// ValidateClaudeCode checks if Claude Code CLI is available and working
func (e *ClaudeExecutor) ValidateClaudeCode() error {
	cmd := exec.Command(e.config.Claude.BinaryPath, "--version")
	
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("claude-code CLI not available at '%s': %w", e.config.Claude.BinaryPath, err)
	}
	
	// Check for API key
	if os.Getenv("ANTHROPIC_API_KEY") == "" {
		return fmt.Errorf("ANTHROPIC_API_KEY environment variable not set")
	}
	
	return nil
}