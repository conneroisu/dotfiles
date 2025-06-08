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

// ClaudeExecutor handles Claude Code CLI execution
type ClaudeExecutor struct {
	config     *config.Config
	binaryPath string
	defaultArgs []string
}

// NewClaudeExecutor creates a new Claude Code executor
func NewClaudeExecutor(cfg *config.Config) (*ClaudeExecutor, error) {
	// Check if Claude Code binary exists
	binaryPath := cfg.Claude.BinaryPath
	if _, err := exec.LookPath(binaryPath); err != nil {
		return nil, fmt.Errorf("claude-code binary not found at %s: %w", binaryPath, err)
	}

	return &ClaudeExecutor{
		config:      cfg,
		binaryPath:  binaryPath,
		defaultArgs: cfg.Claude.DefaultArgs,
	}, nil
}

// Execute executes Claude Code CLI with the given prompt in the job's worktree
func (c *ClaudeExecutor) Execute(job *Job, processedPrompt string) (*JobResult, error) {
	// Create command arguments
	args := append([]string{}, c.defaultArgs...)
	args = append(args, "--directory", job.Worktree.Path)
	
	// If it's a planning phase, add planning-specific args
	if job.Options.Plan {
		args = append(args, "--plan")
	}

	// Create command
	cmd := exec.CommandContext(job.Context, c.binaryPath, args...)
	cmd.Dir = job.Worktree.Path

	// Set environment variables
	cmd.Env = append(os.Environ(),
		fmt.Sprintf("PAR_JOB_ID=%s", job.ID),
		fmt.Sprintf("PAR_WORKTREE=%s", job.Worktree.Name),
		fmt.Sprintf("PAR_BRANCH=%s", job.Worktree.Branch),
	)

	// Prepare stdin with the prompt
	cmd.Stdin = strings.NewReader(processedPrompt)

	// Capture output
	var output strings.Builder
	var errOutput strings.Builder
	cmd.Stdout = &output
	cmd.Stderr = &errOutput

	// Execute command
	startTime := time.Now()
	err := cmd.Run()
	endTime := time.Now()
	duration := endTime.Sub(startTime)

	// Determine exit code
	exitCode := 0
	if err != nil {
		if exitError, ok := err.(*exec.ExitError); ok {
			exitCode = exitError.ExitCode()
		} else {
			exitCode = 1
		}
	}

	// Create result
	result := &JobResult{
		JobID:     job.ID,
		Worktree:  job.Worktree.Name,
		Status:    "success",
		StartTime: startTime,
		EndTime:   endTime,
		Duration:  duration,
		Output:    output.String(),
		ExitCode:  exitCode,
	}

	// Handle errors
	if err != nil {
		result.Status = "failed"
		errorMsg := err.Error()
		if errOutput.Len() > 0 {
			errorMsg = errOutput.String()
		}
		result.ErrorMessage = errorMsg
	}

	// Check for timeout
	if job.Context.Err() == context.DeadlineExceeded {
		result.Status = "timeout"
		result.ErrorMessage = "execution timed out"
	}

	// Try to get commit information if successful
	if result.Status == "success" {
		c.enrichResultWithGitInfo(job, result)
	}

	return result, nil
}

// enrichResultWithGitInfo adds Git information to the result
func (c *ClaudeExecutor) enrichResultWithGitInfo(job *Job, result *JobResult) {
	// Get latest commit hash
	cmd := exec.Command("git", "rev-parse", "HEAD")
	cmd.Dir = job.Worktree.Path
	if output, err := cmd.Output(); err == nil {
		result.CommitHash = strings.TrimSpace(string(output))
	}

	// Get list of changed files
	cmd = exec.Command("git", "diff", "--name-only", "HEAD~1", "HEAD")
	cmd.Dir = job.Worktree.Path
	if output, err := cmd.Output(); err == nil {
		files := strings.Split(strings.TrimSpace(string(output)), "\n")
		if len(files) > 0 && files[0] != "" {
			result.FilesChanged = files
		}
	}
}

// ValidateEnvironment checks if the execution environment is ready
func (c *ClaudeExecutor) ValidateEnvironment() error {
	// Check if binary exists and is executable
	if _, err := exec.LookPath(c.binaryPath); err != nil {
		return fmt.Errorf("claude-code binary not found: %w", err)
	}

	// Test basic execution
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	cmd := exec.CommandContext(ctx, c.binaryPath, "--version")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("claude-code binary test failed: %w", err)
	}

	return nil
}

// GetVersion returns the version of Claude Code CLI
func (c *ClaudeExecutor) GetVersion() (string, error) {
	cmd := exec.Command(c.binaryPath, "--version")
	output, err := cmd.Output()
	if err != nil {
		return "", fmt.Errorf("failed to get claude-code version: %w", err)
	}
	return strings.TrimSpace(string(output)), nil
}