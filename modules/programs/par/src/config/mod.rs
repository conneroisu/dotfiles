use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use std::time::Duration;

use crate::error::{ParError, Result as ParResult};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    #[serde(default)]
    pub defaults: DefaultSettings,
    
    #[serde(default)]
    pub claude: ClaudeSettings,
    
    #[serde(default)]
    pub terminal: TerminalSettings,
    
    #[serde(default)]
    pub worktrees: WorktreeSettings,
    
    #[serde(default)]
    pub prompts: PromptSettings,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DefaultSettings {
    #[serde(default = "default_jobs")]
    pub jobs: usize,
    
    #[serde(with = "humantime_serde", default = "default_timeout")]
    pub timeout: Duration,
    
    #[serde(default = "default_output_dir")]
    pub output_dir: PathBuf,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClaudeSettings {
    #[serde(default = "default_claude_binary")]
    pub binary_path: String,
    
    #[serde(default)]
    pub default_args: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TerminalSettings {
    #[serde(default = "default_true")]
    pub use_ghostty: bool,
    
    #[serde(default = "default_true")]
    pub wait_after_command: bool,
    
    #[serde(default = "default_true")]
    pub new_window_per_job: bool,
    
    #[serde(default)]
    pub show_real_time_output: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorktreeSettings {
    #[serde(default = "default_search_paths")]
    pub search_paths: Vec<PathBuf>,
    
    #[serde(default = "default_exclude_patterns")]
    pub exclude_patterns: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PromptSettings {
    #[serde(default = "default_prompts_dir")]
    pub storage_dir: PathBuf,
    
    #[serde(default = "default_template_engine")]
    pub template_engine: String,
}

impl Config {
    pub fn load() -> ParResult<Self> {
        let config_path = Self::config_path()?;
        
        if config_path.exists() {
            let content = std::fs::read_to_string(&config_path)?;
            let config: Config = serde_yaml::from_str(&content)?;
            Ok(config)
        } else {
            Ok(Self::default())
        }
    }
    
    pub fn save(&self) -> ParResult<()> {
        let config_path = Self::config_path()?;
        
        if let Some(parent) = config_path.parent() {
            std::fs::create_dir_all(parent)?;
        }
        
        let content = serde_yaml::to_string(self)?;
        std::fs::write(config_path, content)?;
        
        Ok(())
    }
    
    fn config_path() -> ParResult<PathBuf> {
        let config_dir = dirs::config_dir()
            .ok_or_else(|| ParError::Config("Failed to get config directory".to_string()))?;
        Ok(config_dir.join("par").join("config.yaml"))
    }
}

impl Default for Config {
    fn default() -> Self {
        Self {
            defaults: DefaultSettings::default(),
            claude: ClaudeSettings::default(),
            terminal: TerminalSettings::default(),
            worktrees: WorktreeSettings::default(),
            prompts: PromptSettings::default(),
        }
    }
}

impl Default for DefaultSettings {
    fn default() -> Self {
        Self {
            jobs: default_jobs(),
            timeout: default_timeout(),
            output_dir: default_output_dir(),
        }
    }
}

impl Default for ClaudeSettings {
    fn default() -> Self {
        Self {
            binary_path: default_claude_binary(),
            default_args: Vec::new(),
        }
    }
}

impl Default for TerminalSettings {
    fn default() -> Self {
        Self {
            use_ghostty: default_true(),
            wait_after_command: default_true(),
            new_window_per_job: default_true(),
            show_real_time_output: false,
        }
    }
}

impl Default for WorktreeSettings {
    fn default() -> Self {
        Self {
            search_paths: default_search_paths(),
            exclude_patterns: default_exclude_patterns(),
        }
    }
}

impl Default for PromptSettings {
    fn default() -> Self {
        Self {
            storage_dir: default_prompts_dir(),
            template_engine: default_template_engine(),
        }
    }
}

fn default_jobs() -> usize {
    num_cpus::get()
}

fn default_timeout() -> Duration {
    Duration::from_secs(1800) // 30 minutes
}

fn default_output_dir() -> PathBuf {
    dirs::data_local_dir()
        .unwrap_or_else(|| PathBuf::from("."))
        .join("par")
        .join("results")
}

fn default_claude_binary() -> String {
    "claude-code".to_string()
}

fn default_true() -> bool {
    true
}

fn default_search_paths() -> Vec<PathBuf> {
    vec![
        dirs::home_dir().unwrap_or_else(|| PathBuf::from(".")).join("projects"),
        dirs::home_dir().unwrap_or_else(|| PathBuf::from(".")).join("work"),
    ]
}

fn default_exclude_patterns() -> Vec<String> {
    vec![
        "*/node_modules/*".to_string(),
        "*/.git/*".to_string(),
        "*/target/*".to_string(),
    ]
}

fn default_prompts_dir() -> PathBuf {
    dirs::data_local_dir()
        .unwrap_or_else(|| PathBuf::from("."))
        .join("par")
        .join("prompts")
}

fn default_template_engine() -> String {
    "tera".to_string()
}