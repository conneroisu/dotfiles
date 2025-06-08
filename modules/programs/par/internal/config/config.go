package config

import (
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/spf13/viper"
)

type Config struct {
	Defaults  DefaultsConfig  `mapstructure:"defaults"`
	Claude    ClaudeConfig    `mapstructure:"claude"`
	Terminal  TerminalConfig  `mapstructure:"terminal"`
	Worktrees WorktreesConfig `mapstructure:"worktrees"`
	Prompts   PromptsConfig   `mapstructure:"prompts"`
}

type DefaultsConfig struct {
	Jobs      int    `mapstructure:"jobs"`
	Timeout   string `mapstructure:"timeout"`
	OutputDir string `mapstructure:"output_dir"`
}

type ClaudeConfig struct {
	BinaryPath   string   `mapstructure:"binary_path"`
	DefaultArgs  []string `mapstructure:"default_args"`
}

type TerminalConfig struct {
	UseGhostty         bool `mapstructure:"use_ghostty"`
	WaitAfterCommand   bool `mapstructure:"wait_after_command"`
	NewWindowPerJob    bool `mapstructure:"new_window_per_job"`
	ShowRealTimeOutput bool `mapstructure:"show_real_time_output"`
}

type WorktreesConfig struct {
	SearchPaths     []string `mapstructure:"search_paths"`
	ExcludePatterns []string `mapstructure:"exclude_patterns"`
}

type PromptsConfig struct {
	StorageDir     string `mapstructure:"storage_dir"`
	TemplateEngine string `mapstructure:"template_engine"`
}

var globalConfig *Config

func Init() error {
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")
	
	configDir, err := getConfigDir()
	if err != nil {
		return fmt.Errorf("failed to get config directory: %w", err)
	}
	
	viper.AddConfigPath(configDir)
	
	setDefaults()
	
	if err := viper.ReadInConfig(); err != nil {
		if _, ok := err.(viper.ConfigFileNotFoundError); ok {
			if err := createDefaultConfig(configDir); err != nil {
				return fmt.Errorf("failed to create default config: %w", err)
			}
		} else {
			return fmt.Errorf("failed to read config: %w", err)
		}
	}
	
	config := &Config{}
	if err := viper.Unmarshal(config); err != nil {
		return fmt.Errorf("failed to unmarshal config: %w", err)
	}
	
	globalConfig = config
	return nil
}

func Get() *Config {
	if globalConfig == nil {
		panic("config not initialized - call config.Init() first")
	}
	return globalConfig
}

func GetTimeoutDuration() (time.Duration, error) {
	if globalConfig == nil {
		return 0, fmt.Errorf("config not initialized")
	}
	return time.ParseDuration(globalConfig.Defaults.Timeout)
}

func setDefaults() {
	homeDir, _ := os.UserHomeDir()
	
	viper.SetDefault("defaults.jobs", 3)
	viper.SetDefault("defaults.timeout", "60m")
	viper.SetDefault("defaults.output_dir", filepath.Join(homeDir, ".local", "share", "par", "results"))
	
	viper.SetDefault("claude.binary_path", "claude-code")
	viper.SetDefault("claude.default_args", []string{"--dangerously-skip-permissions"})
	
	viper.SetDefault("terminal.use_ghostty", true)
	viper.SetDefault("terminal.wait_after_command", true)
	viper.SetDefault("terminal.new_window_per_job", true)
	viper.SetDefault("terminal.show_real_time_output", false)
	
	viper.SetDefault("worktrees.search_paths", []string{
		filepath.Join(homeDir, "projects"),
		filepath.Join(homeDir, "work"),
	})
	viper.SetDefault("worktrees.exclude_patterns", []string{
		"*/node_modules/*",
		"*/.git/*",
		"*/target/*",
	})
	
	viper.SetDefault("prompts.storage_dir", filepath.Join(homeDir, ".local", "share", "par", "prompts"))
	viper.SetDefault("prompts.template_engine", "go")
}

func getConfigDir() (string, error) {
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}
	
	configDir := filepath.Join(homeDir, ".config", "par")
	if err := os.MkdirAll(configDir, 0755); err != nil {
		return "", err
	}
	
	return configDir, nil
}

func createDefaultConfig(configDir string) error {
	configFile := filepath.Join(configDir, "config.yaml")
	
	defaultConfigContent := `# Par Configuration

# Default settings
defaults:
  jobs: 3
  timeout: "60m"
  output_dir: "~/.local/share/par/results"

# Claude Code CLI settings
claude:
  binary_path: "claude-code"
  default_args: ["--dangerously-skip-permissions"]

# Terminal integration settings
terminal:
  use_ghostty: true
  wait_after_command: true
  new_window_per_job: true
  show_real_time_output: false

# Worktree discovery settings
worktrees:
  search_paths:
    - "~/projects"
    - "~/work"
  exclude_patterns:
    - "*/node_modules/*"
    - "*/.git/*"
    - "*/target/*"

# Prompt storage settings
prompts:
  storage_dir: "~/.local/share/par/prompts"
  template_engine: "go"
`
	
	return os.WriteFile(configFile, []byte(defaultConfigContent), 0644)
}

func ExpandPath(path string) string {
	if path[:2] == "~/" {
		homeDir, _ := os.UserHomeDir()
		return filepath.Join(homeDir, path[2:])
	}
	return path
}