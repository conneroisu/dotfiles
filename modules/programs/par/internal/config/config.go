// Package config handles configuration management for par
package config

import (
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/spf13/viper"
	"gopkg.in/yaml.v3"
)

// Config represents the application configuration
type Config struct {
	Defaults  DefaultsConfig  `yaml:"defaults" mapstructure:"defaults"`
	Claude    ClaudeConfig    `yaml:"claude" mapstructure:"claude"`
	Terminal  TerminalConfig  `yaml:"terminal" mapstructure:"terminal"`
	Worktrees WorktreesConfig `yaml:"worktrees" mapstructure:"worktrees"`
	Prompts   PromptsConfig   `yaml:"prompts" mapstructure:"prompts"`
}

// DefaultsConfig contains default settings
type DefaultsConfig struct {
	Jobs      int    `yaml:"jobs" mapstructure:"jobs"`
	Timeout   string `yaml:"timeout" mapstructure:"timeout"`
	OutputDir string `yaml:"output_dir" mapstructure:"output_dir"`
}

// ClaudeConfig contains Claude Code CLI settings
type ClaudeConfig struct {
	BinaryPath  string   `yaml:"binary_path" mapstructure:"binary_path"`
	DefaultArgs []string `yaml:"default_args" mapstructure:"default_args"`
}

// TerminalConfig contains terminal integration settings
type TerminalConfig struct {
	UseGhostty        bool `yaml:"use_ghostty" mapstructure:"use_ghostty"`
	WaitAfterCommand  bool `yaml:"wait_after_command" mapstructure:"wait_after_command"`
	NewWindowPerJob   bool `yaml:"new_window_per_job" mapstructure:"new_window_per_job"`
	ShowRealTimeOutput bool `yaml:"show_real_time_output" mapstructure:"show_real_time_output"`
}

// WorktreesConfig contains worktree discovery settings
type WorktreesConfig struct {
	SearchPaths     []string `yaml:"search_paths" mapstructure:"search_paths"`
	ExcludePatterns []string `yaml:"exclude_patterns" mapstructure:"exclude_patterns"`
}

// PromptsConfig contains prompt storage settings
type PromptsConfig struct {
	StorageDir     string `yaml:"storage_dir" mapstructure:"storage_dir"`
	TemplateEngine string `yaml:"template_engine" mapstructure:"template_engine"`
}

// Load loads the configuration from file and environment
func Load() (*Config, error) {
	// Set defaults
	viper.SetDefault("defaults.jobs", 3)
	viper.SetDefault("defaults.timeout", "60m")
	viper.SetDefault("defaults.output_dir", "~/.local/share/par/results")

	viper.SetDefault("claude.binary_path", "claude-code")
	viper.SetDefault("claude.default_args", []string{"--dangerously-skip-permissions"})

	viper.SetDefault("terminal.use_ghostty", true)
	viper.SetDefault("terminal.wait_after_command", true)
	viper.SetDefault("terminal.new_window_per_job", true)
	viper.SetDefault("terminal.show_real_time_output", false)

	viper.SetDefault("worktrees.search_paths", []string{"~/projects", "~/work"})
	viper.SetDefault("worktrees.exclude_patterns", []string{
		"*/node_modules/*",
		"*/.git/*",
		"*/target/*",
	})

	viper.SetDefault("prompts.storage_dir", "~/.local/share/par/prompts")
	viper.SetDefault("prompts.template_engine", "go")

	var cfg Config
	err := viper.Unmarshal(&cfg)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal config: %w", err)
	}

	// Expand paths
	cfg.Defaults.OutputDir = expandPath(cfg.Defaults.OutputDir)
	cfg.Prompts.StorageDir = expandPath(cfg.Prompts.StorageDir)

	for i, path := range cfg.Worktrees.SearchPaths {
		cfg.Worktrees.SearchPaths[i] = expandPath(path)
	}

	// Validate configuration
	if err := cfg.Validate(); err != nil {
		return nil, fmt.Errorf("invalid configuration: %w", err)
	}

	return &cfg, nil
}

// Validate validates the configuration
func (c *Config) Validate() error {
	if c.Defaults.Jobs <= 0 {
		return fmt.Errorf("defaults.jobs must be greater than 0")
	}

	if _, err := time.ParseDuration(c.Defaults.Timeout); err != nil {
		return fmt.Errorf("invalid defaults.timeout: %w", err)
	}

	if c.Claude.BinaryPath == "" {
		return fmt.Errorf("claude.binary_path cannot be empty")
	}

	if len(c.Worktrees.SearchPaths) == 0 {
		return fmt.Errorf("worktrees.search_paths cannot be empty")
	}

	return nil
}

// Save saves the configuration to file
func (c *Config) Save(path string) error {
	// Ensure directory exists
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("failed to create config directory: %w", err)
	}

	data, err := yaml.Marshal(c)
	if err != nil {
		return fmt.Errorf("failed to marshal config: %w", err)
	}

	err = os.WriteFile(path, data, 0644)
	if err != nil {
		return fmt.Errorf("failed to write config file: %w", err)
	}

	return nil
}

// GetTimeout returns the timeout duration
func (c *Config) GetTimeout() time.Duration {
	duration, err := time.ParseDuration(c.Defaults.Timeout)
	if err != nil {
		return 60 * time.Minute // fallback
	}
	return duration
}

// GetOutputDir returns the expanded output directory path
func (c *Config) GetOutputDir() string {
	return expandPath(c.Defaults.OutputDir)
}

// GetPromptsDir returns the expanded prompts directory path
func (c *Config) GetPromptsDir() string {
	return expandPath(c.Prompts.StorageDir)
}

// expandPath expands ~ to home directory
func expandPath(path string) string {
	if len(path) > 0 && path[0] == '~' {
		home, err := os.UserHomeDir()
		if err != nil {
			return path
		}
		return filepath.Join(home, path[1:])
	}
	return path
}

// EnsureDirectories creates necessary directories
func (c *Config) EnsureDirectories() error {
	dirs := []string{
		c.GetOutputDir(),
		c.GetPromptsDir(),
	}

	for _, dir := range dirs {
		if err := os.MkdirAll(dir, 0755); err != nil {
			return fmt.Errorf("failed to create directory %s: %w", dir, err)
		}
	}

	return nil
}