package terminal

import (
	"fmt"
	"os/exec"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/config"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/executor"
)

// GhosttyExecutor handles execution of jobs in Ghostty terminal windows
type GhosttyExecutor struct {
	config *config.Config
}

// NewGhosttyExecutor creates a new Ghostty executor
func NewGhosttyExecutor(config *config.Config) *GhosttyExecutor {
	return &GhosttyExecutor{
		config: config,
	}
}

// ExecuteJob executes a job in a new Ghostty window
func (g *GhosttyExecutor) ExecuteJob(job *executor.Job) error {
	// Build Ghostty command
	cmd := g.buildGhosttyCommand(job)

	// Execute in background
	if err := cmd.Start(); err != nil {
		return fmt.Errorf("failed to start Ghostty window: %w", err)
	}

	// Note: We don't wait for the command to complete as it runs in its own window
	// Job completion tracking would need to be handled differently for Ghostty mode

	return nil
}

// buildGhosttyCommand builds the Ghostty command for a job
func (g *GhosttyExecutor) buildGhosttyCommand(job *executor.Job) *exec.Cmd {
	// Create the command to run inside Ghostty
	claudeCmd := fmt.Sprintf("cd %s && echo '%s' | %s --print",
		job.Worktree.Path,
		job.Prompt,
		g.config.Claude.BinaryPath)

	args := []string{
		"-e", claudeCmd,
	}

	// Add window title
	title := fmt.Sprintf("Par: %s [%s]", job.Worktree.Name, job.Worktree.Branch)
	args = append(args, "--title="+title)

	// Add wait-after-command if configured
	if g.config.Terminal.WaitAfterCommand {
		args = append(args, "--wait-after-command=true")
	}

	return exec.Command("ghostty", args...)
}

// IsGhosttyAvailable checks if Ghostty is available on the system
func (g *GhosttyExecutor) IsGhosttyAvailable() bool {
	cmd := exec.Command("ghostty", "--version")
	err := cmd.Run()
	return err == nil
}
