package prompts

import (
	"fmt"
	"os"
	"path/filepath"
	"time"

	"gopkg.in/yaml.v3"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/config"
)

type Prompt struct {
	Name        string                 `yaml:"name" json:"name"`
	Description string                 `yaml:"description" json:"description"`
	Content     string                 `yaml:"content" json:"content"`
	IsTemplate  bool                   `yaml:"is_template" json:"is_template"`
	Variables   map[string]interface{} `yaml:"variables,omitempty" json:"variables,omitempty"`
	CreatedAt   time.Time             `yaml:"created_at" json:"created_at"`
	UpdatedAt   time.Time             `yaml:"updated_at" json:"updated_at"`
	Tags        []string              `yaml:"tags,omitempty" json:"tags,omitempty"`
}

type Manager struct {
	storageDir string
}

func NewManager() (*Manager, error) {
	cfg := config.Get()
	storageDir := config.ExpandPath(cfg.Prompts.StorageDir)
	
	if err := os.MkdirAll(storageDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create prompts storage directory: %w", err)
	}
	
	return &Manager{
		storageDir: storageDir,
	}, nil
}

func (m *Manager) Save(prompt *Prompt) error {
	if prompt.Name == "" {
		return fmt.Errorf("prompt name cannot be empty")
	}
	
	prompt.UpdatedAt = time.Now()
	if prompt.CreatedAt.IsZero() {
		prompt.CreatedAt = time.Now()
	}
	
	promptFile := filepath.Join(m.storageDir, prompt.Name+".yaml")
	
	data, err := yaml.Marshal(prompt)
	if err != nil {
		return fmt.Errorf("failed to marshal prompt: %w", err)
	}
	
	if err := os.WriteFile(promptFile, data, 0644); err != nil {
		return fmt.Errorf("failed to write prompt file: %w", err)
	}
	
	return nil
}

func (m *Manager) Load(name string) (*Prompt, error) {
	promptFile := filepath.Join(m.storageDir, name+".yaml")
	
	data, err := os.ReadFile(promptFile)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, fmt.Errorf("prompt '%s' not found", name)
		}
		return nil, fmt.Errorf("failed to read prompt file: %w", err)
	}
	
	var prompt Prompt
	if err := yaml.Unmarshal(data, &prompt); err != nil {
		return nil, fmt.Errorf("failed to unmarshal prompt: %w", err)
	}
	
	return &prompt, nil
}

func (m *Manager) List() ([]*Prompt, error) {
	files, err := filepath.Glob(filepath.Join(m.storageDir, "*.yaml"))
	if err != nil {
		return nil, fmt.Errorf("failed to glob prompt files: %w", err)
	}
	
	var prompts []*Prompt
	for _, file := range files {
		name := filepath.Base(file)
		name = name[:len(name)-len(filepath.Ext(name))] // remove .yaml extension
		
		prompt, err := m.Load(name)
		if err != nil {
			continue // skip invalid prompts
		}
		
		prompts = append(prompts, prompt)
	}
	
	return prompts, nil
}

func (m *Manager) Delete(name string) error {
	promptFile := filepath.Join(m.storageDir, name+".yaml")
	
	if err := os.Remove(promptFile); err != nil {
		if os.IsNotExist(err) {
			return fmt.Errorf("prompt '%s' not found", name)
		}
		return fmt.Errorf("failed to delete prompt: %w", err)
	}
	
	return nil
}

func (m *Manager) Exists(name string) bool {
	promptFile := filepath.Join(m.storageDir, name+".yaml")
	_, err := os.Stat(promptFile)
	return err == nil
}

func (m *Manager) GetStorageDir() string {
	return m.storageDir
}

func (m *Manager) ValidateName(name string) error {
	if name == "" {
		return fmt.Errorf("prompt name cannot be empty")
	}
	
	if len(name) > 50 {
		return fmt.Errorf("prompt name too long (max 50 characters)")
	}
	
	// Check for invalid characters
	for _, char := range name {
		if !((char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z') || 
			 (char >= '0' && char <= '9') || char == '-' || char == '_') {
			return fmt.Errorf("prompt name contains invalid character: %c", char)
		}
	}
	
	return nil
}

func CreateDefaultPrompt(name, description string) *Prompt {
	return &Prompt{
		Name:        name,
		Description: description,
		Content:     "",
		IsTemplate:  false,
		Variables:   make(map[string]interface{}),
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
		Tags:        []string{},
	}
}

func CreateTemplatePrompt(name, description string) *Prompt {
	content := `# {{.ProjectName}} - {{.TaskName}}

## Task Description
{{.Description}}

## Context
Project: {{.ProjectName}}
Branch: {{.BranchName}}
Worktree: {{.WorktreePath}}

## Instructions
{{.Instructions}}

## Expected Outcome
{{.ExpectedOutcome}}`

	return &Prompt{
		Name:        name,
		Description: description,
		Content:     content,
		IsTemplate:  true,
		Variables: map[string]interface{}{
			"TaskName":        "",
			"Description":     "",
			"Instructions":    "",
			"ExpectedOutcome": "",
		},
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
		Tags:      []string{"template"},
	}
}