package terminal

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"time"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/config"
)

// GhosttyExecutor handles Ghostty terminal integration
type GhosttyExecutor struct {
	config *config.Config
}

// NewGhosttyExecutor creates a new Ghostty executor
func NewGhosttyExecutor(cfg *config.Config) (*GhosttyExecutor, error) {
	// Check if ghostty is available
	if _, err := exec.LookPath("ghostty"); err != nil {
		return nil, fmt.Errorf("ghostty not found in PATH: %w", err)
	}

	return &GhosttyExecutor{
		config: cfg,
	}, nil
}

// Execute executes a job in a new Ghostty window
func (g *GhosttyExecutor) Execute(job interface{}, processedPrompt string) (interface{}, error) {
	// Create a temporary script to run in the terminal
	scriptPath, err := g.createExecutionScript(job, processedPrompt)
	if err != nil {
		return nil, fmt.Errorf("failed to create execution script: %w", err)
	}
	defer os.Remove(scriptPath) // Clean up script after execution

	// Build ghostty command
	cmd := g.buildGhosttyCommand(job, scriptPath)

	// Execute command
	startTime := time.Now()
	err = cmd.Run()
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
	result := &executor.JobResult{
		JobID:     job.ID,
		Worktree:  job.Worktree.Name,
		Status:    "success",
		StartTime: startTime,
		EndTime:   endTime,
		Duration:  duration,
		Output:    "Executed in Ghostty terminal", // Terminal output not captured
		ExitCode:  exitCode,
	}

	// Handle errors
	if err != nil {
		result.Status = "failed"
		result.ErrorMessage = err.Error()
	}

	// Check for timeout
	if job.Context.Err() == context.DeadlineExceeded {
		result.Status = "timeout"
		result.ErrorMessage = "execution timed out"
	}

	return result, nil
}

// createExecutionScript creates a temporary script to execute in the terminal
func (g *GhosttyExecutor) createExecutionScript(job *executor.Job, prompt string) (string, error) {
	// Create temporary file
	tmpFile, err := os.CreateTemp("", "par-job-*.sh")
	if err != nil {
		return "", fmt.Errorf("failed to create temp file: %w", err)
	}
	defer tmpFile.Close()

	// Write script content
	script := fmt.Sprintf(`#!/bin/bash
set -e

echo "Par Job: %s"
echo "Worktree: %s (%s)"
echo "Branch: %s"
echo "========================================"
echo

cd "%s"

# Run Claude Code with the prompt
echo "%s" | %s %s --directory="%s"

echo
echo "========================================"
echo "Job completed. Press any key to close..."
read -n 1
`, job.ID, job.Worktree.Name, job.Worktree.Path, job.Worktree.Branch,
		job.Worktree.Path, strings.ReplaceAll(prompt, `"`, `\"`),
		g.config.Claude.BinaryPath, strings.Join(g.config.Claude.DefaultArgs, " "), job.Worktree.Path)

	if _, err := tmpFile.WriteString(script); err != nil {
		return "", fmt.Errorf("failed to write script: %w", err)
	}

	// Make script executable
	if err := os.Chmod(tmpFile.Name(), 0755); err != nil {
		return "", fmt.Errorf("failed to make script executable: %w", err)
	}

	return tmpFile.Name(), nil
}

// buildGhosttyCommand builds the ghostty command with appropriate options
func (g *GhosttyExecutor) buildGhosttyCommand(job *executor.Job, scriptPath string) *exec.Cmd {
	args := []string{
		"-e", scriptPath,
	}

	// Add title
	title := fmt.Sprintf("Par: %s (%s)", job.Worktree.Name, job.Worktree.Branch)
	args = append(args, "--title", title)

	// Add wait after command if configured
	if g.config.Terminal.WaitAfterCommand {
		args = append(args, "--wait-after-command")
	}

	return exec.CommandContext(job.Context, "ghostty", args...)
}

// IsAvailable checks if Ghostty is available
func (g *GhosttyExecutor) IsAvailable() bool {
	_, err := exec.LookPath("ghostty")
	return err == nil
}