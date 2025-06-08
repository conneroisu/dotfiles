// Package terminal handles terminal integration for par
package terminal

import (
	"fmt"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/config"
)

// Manager handles terminal session management
type Manager struct {
	config  *config.Config
	ghostty *GhosttyExecutor
}

// NewManager creates a new terminal manager
func NewManager(cfg *config.Config) (*Manager, error) {
	ghostty, err := NewGhosttyExecutor(cfg)
	if err != nil {
		return nil, fmt.Errorf("failed to initialize ghostty executor: %w", err)
	}

	return &Manager{
		config:  cfg,
		ghostty: ghostty,
	}, nil
}

// Execute executes a job in a terminal window
func (m *Manager) Execute(job interface{}, processedPrompt string) (interface{}, error) {
	if m.config.Terminal.UseGhostty {
		return m.ghostty.Execute(job, processedPrompt)
	}

	// Fallback to direct execution if no terminal configured
	return nil, fmt.Errorf("no terminal executor configured")
}