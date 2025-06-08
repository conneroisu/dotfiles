// Package prompts handles prompt storage and retrieval
package prompts

import (
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/config"
	"gopkg.in/yaml.v3"
)

// Manager handles prompt operations
type Manager struct {
	storageDir string
	config     *config.Config
}

// Prompt represents a stored prompt
type Prompt struct {
	Name        string            `yaml:"name"`
	Description string            `yaml:"description"`
	Content     string            `yaml:"content"`
	IsTemplate  bool              `yaml:"is_template"`
	Variables   map[string]string `yaml:"variables,omitempty"`
	CreatedAt   time.Time         `yaml:"created_at"`
	ModifiedAt  time.Time         `yaml:"modified_at"`
}

// NewManager creates a new prompt manager
func NewManager() (*Manager, error) {
	cfg, err := config.Load()
	if err != nil {
		return nil, fmt.Errorf("failed to load config: %w", err)
	}

	storageDir := cfg.GetPromptsDir()
	
	// Ensure storage directory exists
	if err := os.MkdirAll(storageDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create prompts directory: %w", err)
	}

	return &Manager{
		storageDir: storageDir,
		config:     cfg,
	}, nil
}

// Save saves a prompt to storage
func (m *Manager) Save(prompt *Prompt) error {
	if prompt.Name == "" {
		return fmt.Errorf("prompt name cannot be empty")
	}

	// Set timestamps
	now := time.Now()
	if prompt.CreatedAt.IsZero() {
		prompt.CreatedAt = now
	}
	prompt.ModifiedAt = now

	// Save to file
	filePath := filepath.Join(m.storageDir, prompt.Name+".yaml")
	data, err := yaml.Marshal(prompt)
	if err != nil {
		return fmt.Errorf("failed to marshal prompt: %w", err)
	}

	err = os.WriteFile(filePath, data, 0644)
	if err != nil {
		return fmt.Errorf("failed to write prompt file: %w", err)
	}

	return nil
}

// Load loads a prompt by name
func (m *Manager) Load(name string) (*Prompt, error) {
	filePath := filepath.Join(m.storageDir, name+".yaml")
	data, err := os.ReadFile(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to read prompt file: %w", err)
	}

	var prompt Prompt
	err = yaml.Unmarshal(data, &prompt)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal prompt: %w", err)
	}

	return &prompt, nil
}

// List returns all available prompts
func (m *Manager) List() ([]*Prompt, error) {
	entries, err := os.ReadDir(m.storageDir)
	if err != nil {
		return nil, fmt.Errorf("failed to read prompts directory: %w", err)
	}

	var prompts []*Prompt
	for _, entry := range entries {
		if entry.IsDir() || !strings.HasSuffix(entry.Name(), ".yaml") {
			continue
		}

		name := strings.TrimSuffix(entry.Name(), ".yaml")
		prompt, err := m.Load(name)
		if err != nil {
			// Skip invalid prompts
			continue
		}
		prompts = append(prompts, prompt)
	}

	// Sort by modified time (newest first)
	sort.Slice(prompts, func(i, j int) bool {
		return prompts[i].ModifiedAt.After(prompts[j].ModifiedAt)
	})

	return prompts, nil
}

// Delete deletes a prompt by name
func (m *Manager) Delete(name string) error {
	filePath := filepath.Join(m.storageDir, name+".yaml")
	err := os.Remove(filePath)
	if err != nil {
		return fmt.Errorf("failed to delete prompt: %w", err)
	}
	return nil
}

// Exists checks if a prompt exists
func (m *Manager) Exists(name string) bool {
	filePath := filepath.Join(m.storageDir, name+".yaml")
	_, err := os.Stat(filePath)
	return err == nil
}

// GetStorageDir returns the storage directory path
func (m *Manager) GetStorageDir() string {
	return m.storageDir
}