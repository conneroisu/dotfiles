package config

import (
	"fmt"
	"log/slog"
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
	UseGhostty        bool `yaml:"use_ghostty"`
	WaitAfterCommand  bool `yaml:"wait_after_command"`
	NewWindowPerJob   bool `yaml:"new_window_per_job"`
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
	slog.Debug("Loading configuration")
	
	configPath, err := getConfigPath()
	if err != nil {
		slog.Debug("Failed to get config path", "error", err)
		return nil, fmt.Errorf("failed to get config path: %w", err)
	}
	
	slog.Debug("Config path resolved", "path", configPath)
	
	// If config file doesn't exist, return default config
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		slog.Debug("Config file does not exist, using defaults", "path", configPath)
		return DefaultConfig(), nil
	}
	
	slog.Debug("Reading config file", "path", configPath)
	data, err := os.ReadFile(configPath)
	if err != nil {
		slog.Debug("Failed to read config file", "path", configPath, "error", err)
		return nil, fmt.Errorf("failed to read config file: %w", err)
	}
	
	config := DefaultConfig()
	if err := yaml.Unmarshal(data, config); err != nil {
		slog.Debug("Failed to parse config file", "path", configPath, "error", err)
		return nil, fmt.Errorf("failed to parse config file: %w", err)
	}
	
	slog.Debug("Configuration loaded successfully", "path", configPath, "search_paths", len(config.Worktrees.SearchPaths))
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