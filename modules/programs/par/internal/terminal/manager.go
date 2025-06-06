package terminal

import (
	"fmt"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/config"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/executor"
)

// Manager handles terminal session management
type Manager struct {
	config      *config.Config
	ghosttyExec *GhosttyExecutor
}

// NewManager creates a new terminal manager
func NewManager(config *config.Config) *Manager {
	return &Manager{
		config:      config,
		ghosttyExec: NewGhosttyExecutor(config),
	}
}

// ExecuteJobInTerminal executes a job in a terminal window
func (m *Manager) ExecuteJobInTerminal(job *executor.Job) error {
	if job == nil {
		return fmt.Errorf("job cannot be nil")
	}

	if !m.config.Terminal.UseGhostty {
		return fmt.Errorf("terminal execution not enabled")
	}

	if !m.ghosttyExec.IsGhosttyAvailable() {
		return fmt.Errorf("ghostty terminal not available")
	}

	return m.ghosttyExec.ExecuteJob(job)
}

// SupportsTerminalExecution returns true if terminal execution is supported
func (m *Manager) SupportsTerminalExecution() bool {
	return m.config.Terminal.UseGhostty && m.ghosttyExec.IsGhosttyAvailable()
}
