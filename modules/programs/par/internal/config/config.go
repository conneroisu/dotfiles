package config

import (
	"fmt"
	"os"
	"path/filepath"
	"time"

	"gopkg.in/yaml.v3"
)

// Config represents the main configuration for par
type Config struct {
	Defaults  Defaults  `yaml:"defaults"`
	Claude    Claude    `yaml:"claude"`
	Terminal  Terminal  `yaml:"terminal"`
	Worktrees Worktrees `yaml:"worktrees"`
	Prompts   Prompts   `yaml:"prompts"`
}

// Defaults contains default settings for par operations
type Defaults struct {
	Jobs      int           `yaml:"jobs"`
	Timeout   time.Duration `yaml:"timeout"`
	OutputDir string        `yaml:"output_dir"`
}

// Claude contains Claude Code CLI settings
type Claude struct {
	BinaryPath  string   `yaml:"binary_path"`
	DefaultArgs []string `yaml:"default_args"`
}

// Terminal contains terminal integration settings
type Terminal struct {
	UseGhostty         bool `yaml:"use_ghostty"`
	WaitAfterCommand   bool `yaml:"wait_after_command"`
	NewWindowPerJob    bool `yaml:"new_window_per_job"`
	ShowRealTimeOutput bool `yaml:"show_real_time_output"`
}

// Worktrees contains worktree discovery settings
type Worktrees struct {
	SearchPaths     []string `yaml:"search_paths"`
	ExcludePatterns []string `yaml:"exclude_patterns"`
}

// Prompts contains prompt storage settings
type Prompts struct {
	StorageDir     string `yaml:"storage_dir"`
	TemplateEngine string `yaml:"template_engine"`
}

// DefaultConfig returns the default configuration
func DefaultConfig() *Config {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		// Use a safe fallback if home directory cannot be determined
		homeDir = "/tmp/par"
	}

	return &Config{
		Defaults: Defaults{
			Jobs:      4,
			Timeout:   30 * time.Minute,
			OutputDir: filepath.Join(homeDir, ".local", "share", "par", "results"),
		},
		Claude: Claude{
			BinaryPath:  "claude-code",
			DefaultArgs: []string{},
		},
		Terminal: Terminal{
			UseGhostty:         true,
			WaitAfterCommand:   true,
			NewWindowPerJob:    true,
			ShowRealTimeOutput: false,
		},
		Worktrees: Worktrees{
			SearchPaths: []string{
				filepath.Join(homeDir, "projects"),
				filepath.Join(homeDir, "work"),
			},
			ExcludePatterns: []string{
				"*/node_modules/*",
				"*/.git/*",
				"*/target/*",
			},
		},
		Prompts: Prompts{
			StorageDir:     filepath.Join(homeDir, ".local", "share", "par", "prompts"),
			TemplateEngine: "go-template",
		},
	}
}

// Load loads configuration from the config file or returns default config
func Load() (*Config, error) {
	configPath, err := getConfigPath()
	if err != nil {
		return nil, fmt.Errorf("failed to get config path: %w", err)
	}

	// If config file doesn't exist, return default config
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		config := DefaultConfig()
		if err := config.Validate(); err != nil {
			return nil, fmt.Errorf("default config validation failed: %w", err)
		}
		return config, nil
	}

	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}

	config := DefaultConfig()
	if err := yaml.Unmarshal(data, config); err != nil {
		return nil, fmt.Errorf("failed to parse config file: %w", err)
	}

	if err := config.Validate(); err != nil {
		return nil, fmt.Errorf("config validation failed: %w", err)
	}

	return config, nil
}

// Save saves the configuration to the config file
func (c *Config) Save() error {
	configPath, err := getConfigPath()
	if err != nil {
		return fmt.Errorf("failed to get config path: %w", err)
	}

	// Ensure config directory exists
	if err := os.MkdirAll(filepath.Dir(configPath), 0755); err != nil {
		return fmt.Errorf("failed to create config directory: %w", err)
	}

	data, err := yaml.Marshal(c)
	if err != nil {
		return fmt.Errorf("failed to marshal config: %w", err)
	}

	if err := os.WriteFile(configPath, data, 0644); err != nil {
		return fmt.Errorf("failed to write config file: %w", err)
	}

	return nil
}

// getConfigPath returns the path to the configuration file
func getConfigPath() (string, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("failed to get user home directory: %w", err)
	}
	return filepath.Join(homeDir, ".config", "par", "config.yaml"), nil
}

// Validate validates the configuration settings
func (c *Config) Validate() error {
	if c.Defaults.Jobs <= 0 {
		return fmt.Errorf("jobs must be greater than 0, got %d", c.Defaults.Jobs)
	}
	if c.Defaults.Jobs > 100 {
		return fmt.Errorf("jobs must be less than or equal to 100, got %d", c.Defaults.Jobs)
	}
	if c.Defaults.Timeout <= 0 {
		return fmt.Errorf("timeout must be greater than 0, got %v", c.Defaults.Timeout)
	}
	if c.Claude.BinaryPath == "" {
		return fmt.Errorf("claude binary path cannot be empty")
	}
	if c.Defaults.OutputDir == "" {
		return fmt.Errorf("output directory cannot be empty")
	}
	if c.Prompts.StorageDir == "" {
		return fmt.Errorf("prompts storage directory cannot be empty")
	}
	return nil
}

// EnsureDirectories ensures all necessary directories exist
func (c *Config) EnsureDirectories() error {
	dirs := []string{
		c.Defaults.OutputDir,
		c.Prompts.StorageDir,
	}

	for _, dir := range dirs {
		if err := os.MkdirAll(dir, 0755); err != nil {
			return fmt.Errorf("failed to create directory %s: %w", dir, err)
		}
	}

	return nil
}
