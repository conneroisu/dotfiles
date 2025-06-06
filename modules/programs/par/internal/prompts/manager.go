package prompts

import (
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"strings"
	"time"

	"gopkg.in/yaml.v3"
)

// Prompt represents a stored prompt with metadata
type Prompt struct {
	Name        string              `yaml:"name"`
	Description string              `yaml:"description"`
	Created     time.Time           `yaml:"created"`
	Template    bool                `yaml:"template"`
	Variables   []Variable          `yaml:"variables,omitempty"`
	Content     string              `yaml:"prompt"`
}

// Variable represents a template variable definition
type Variable struct {
	Name        string `yaml:"name"`
	Description string `yaml:"description"`
	Default     string `yaml:"default,omitempty"`
	Required    bool   `yaml:"required,omitempty"`
}

// Manager handles prompt storage and retrieval
type Manager struct {
	storageDir string
}

// NewManager creates a new prompt manager
func NewManager(storageDir string) *Manager {
	return &Manager{
		storageDir: storageDir,
	}
}

// Save stores a prompt to the filesystem
func (m *Manager) Save(prompt *Prompt) error {
	slog.Debug("Saving prompt", "name", prompt.Name, "template", prompt.Template, "variables_count", len(prompt.Variables))
	
	if err := os.MkdirAll(m.storageDir, 0755); err != nil {
		slog.Debug("Failed to create storage directory", "dir", m.storageDir, "error", err)
		return fmt.Errorf("failed to create storage directory: %w", err)
	}
	
	filename := sanitizeFilename(prompt.Name) + ".yaml"
	filepath := filepath.Join(m.storageDir, filename)
	slog.Debug("Writing prompt to file", "filename", filename, "path", filepath)
	
	data, err := yaml.Marshal(prompt)
	if err != nil {
		slog.Debug("Failed to marshal prompt", "name", prompt.Name, "error", err)
		return fmt.Errorf("failed to marshal prompt: %w", err)
	}
	
	if err := os.WriteFile(filepath, data, 0644); err != nil {
		slog.Debug("Failed to write prompt file", "path", filepath, "error", err)
		return fmt.Errorf("failed to write prompt file: %w", err)
	}
	
	slog.Debug("Prompt saved successfully", "name", prompt.Name, "path", filepath)
	return nil
}

// Load retrieves a prompt by name
func (m *Manager) Load(name string) (*Prompt, error) {
	slog.Debug("Loading prompt", "name", name)
	filename := sanitizeFilename(name) + ".yaml"
	filepath := filepath.Join(m.storageDir, filename)
	slog.Debug("Reading prompt file", "filename", filename, "path", filepath)
	
	data, err := os.ReadFile(filepath)
	if err != nil {
		if os.IsNotExist(err) {
			slog.Debug("Prompt file not found", "name", name, "path", filepath)
			return nil, fmt.Errorf("prompt '%s' not found", name)
		}
		slog.Debug("Failed to read prompt file", "path", filepath, "error", err)
		return nil, fmt.Errorf("failed to read prompt file: %w", err)
	}
	
	var prompt Prompt
	if err := yaml.Unmarshal(data, &prompt); err != nil {
		slog.Debug("Failed to parse prompt file", "path", filepath, "error", err)
		return nil, fmt.Errorf("failed to parse prompt file: %w", err)
	}
	
	slog.Debug("Prompt loaded successfully", "name", name, "template", prompt.Template, "variables_count", len(prompt.Variables))
	return &prompt, nil
}

// List returns all available prompts
func (m *Manager) List() ([]*Prompt, error) {
	if _, err := os.Stat(m.storageDir); os.IsNotExist(err) {
		return []*Prompt{}, nil
	}
	
	files, err := os.ReadDir(m.storageDir)
	if err != nil {
		return nil, fmt.Errorf("failed to read storage directory: %w", err)
	}
	
	var prompts []*Prompt
	for _, file := range files {
		if !file.IsDir() && strings.HasSuffix(file.Name(), ".yaml") {
			name := strings.TrimSuffix(file.Name(), ".yaml")
			prompt, err := m.Load(name)
			if err != nil {
				// Skip invalid files but continue processing
				continue
			}
			prompts = append(prompts, prompt)
		}
	}
	
	return prompts, nil
}

// Delete removes a prompt by name
func (m *Manager) Delete(name string) error {
	filename := sanitizeFilename(name) + ".yaml"
	filepath := filepath.Join(m.storageDir, filename)
	
	if err := os.Remove(filepath); err != nil {
		if os.IsNotExist(err) {
			return fmt.Errorf("prompt '%s' not found", name)
		}
		return fmt.Errorf("failed to delete prompt: %w", err)
	}
	
	return nil
}

// Exists checks if a prompt exists
func (m *Manager) Exists(name string) bool {
	filename := sanitizeFilename(name) + ".yaml"
	filepath := filepath.Join(m.storageDir, filename)
	
	_, err := os.Stat(filepath)
	return !os.IsNotExist(err)
}

// sanitizeFilename removes invalid characters from filenames
func sanitizeFilename(name string) string {
	// Replace invalid characters with underscores
	invalid := []string{"/", "\\", ":", "*", "?", "\"", "<", ">", "|"}
	result := name
	for _, char := range invalid {
		result = strings.ReplaceAll(result, char, "_")
	}
	return result
}