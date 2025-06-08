use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use tera::{Context, Tera};

use crate::config::Config;
use crate::error::{ParError, Result};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Prompt {
    pub name: String,
    pub content: String,
    pub description: Option<String>,
    pub created: DateTime<Utc>,
    pub template: bool,
    #[serde(default)]
    pub variables: Vec<TemplateVariable>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TemplateVariable {
    pub name: String,
    pub description: Option<String>,
    pub default: Option<String>,
    pub required: bool,
}

pub struct PromptManager {
    storage_dir: PathBuf,
    tera: Tera,
}

impl Prompt {
    pub fn new(name: String, content: String, description: Option<String>, template: bool) -> Self {
        Self {
            name,
            content,
            description,
            created: Utc::now(),
            template,
            variables: Vec::new(),
        }
    }
    
    pub fn with_variables(mut self, variables: Vec<TemplateVariable>) -> Self {
        self.variables = variables;
        self
    }
}

impl PromptManager {
    pub fn new() -> Result<Self> {
        let config = Config::load()?;
        let storage_dir = config.prompts.storage_dir;
        
        std::fs::create_dir_all(&storage_dir)?;
        
        let tera = Tera::new(&format!("{}/**/*.tera", storage_dir.display()))
            .map_err(|e| ParError::Template(e))?;
        
        Ok(Self { storage_dir, tera })
    }
    
    pub fn add_prompt(&self, prompt: Prompt) -> Result<()> {
        let file_path = self.prompt_path(&prompt.name);
        
        if file_path.exists() {
            return Err(ParError::Prompt(format!(
                "Prompt '{}' already exists",
                prompt.name
            )));
        }
        
        let content = serde_yaml::to_string(&prompt)?;
        std::fs::write(file_path, content)?;
        
        Ok(())
    }
    
    pub fn get_prompt(&self, name: &str) -> Result<Option<Prompt>> {
        let file_path = self.prompt_path(name);
        
        if !file_path.exists() {
            return Ok(None);
        }
        
        let content = std::fs::read_to_string(file_path)?;
        let prompt: Prompt = serde_yaml::from_str(&content)?;
        
        Ok(Some(prompt))
    }
    
    pub fn list_prompts(&self) -> Result<Vec<Prompt>> {
        let mut prompts = Vec::new();
        
        for entry in std::fs::read_dir(&self.storage_dir)? {
            let entry = entry?;
            let path = entry.path();
            
            if path.extension().and_then(|s| s.to_str()) == Some("yaml") {
                let content = std::fs::read_to_string(&path)?;
                if let Ok(prompt) = serde_yaml::from_str::<Prompt>(&content) {
                    prompts.push(prompt);
                }
            }
        }
        
        prompts.sort_by(|a, b| b.created.cmp(&a.created));
        Ok(prompts)
    }
    
    pub fn delete_prompt(&self, name: &str) -> Result<()> {
        let file_path = self.prompt_path(name);
        
        if !file_path.exists() {
            return Err(ParError::Prompt(format!("Prompt '{}' not found", name)));
        }
        
        std::fs::remove_file(file_path)?;
        Ok(())
    }
    
    pub fn process_template(&self, prompt: &Prompt, vars: &HashMap<String, String>) -> Result<String> {
        if !prompt.template {
            return Ok(prompt.content.clone());
        }
        
        // Validate required variables
        for var in &prompt.variables {
            if var.required && !vars.contains_key(&var.name) {
                return Err(ParError::Prompt(format!(
                    "Required variable '{}' not provided",
                    var.name
                )));
            }
        }
        
        // Build context with variables and defaults
        let mut context = Context::new();
        
        for var in &prompt.variables {
            let value = vars
                .get(&var.name)
                .cloned()
                .or_else(|| var.default.clone())
                .unwrap_or_default();
            context.insert(&var.name, &value);
        }
        
        // Process template
        let mut tera = Tera::default();
        tera.add_raw_template("prompt", &prompt.content)?;
        
        let rendered = tera.render("prompt", &context)?;
        Ok(rendered)
    }
    
    fn prompt_path(&self, name: &str) -> PathBuf {
        self.storage_dir.join(format!("{}.yaml", name))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;
    
    #[test]
    fn test_prompt_creation() {
        let prompt = Prompt::new(
            "test".to_string(),
            "Test content".to_string(),
            Some("Test description".to_string()),
            false,
        );
        
        assert_eq!(prompt.name, "test");
        assert_eq!(prompt.content, "Test content");
        assert_eq!(prompt.description, Some("Test description".to_string()));
        assert!(!prompt.template);
    }
    
    #[test]
    fn test_template_processing() {
        let prompt = Prompt::new(
            "template_test".to_string(),
            "Hello {{ name }}!".to_string(),
            None,
            true,
        )
        .with_variables(vec![TemplateVariable {
            name: "name".to_string(),
            description: Some("User name".to_string()),
            default: Some("World".to_string()),
            required: false,
        }]);
        
        let temp_dir = TempDir::new().unwrap();
        std::env::set_var("HOME", temp_dir.path());
        
        let manager = PromptManager::new().unwrap();
        
        // Test with provided variable
        let mut vars = HashMap::new();
        vars.insert("name".to_string(), "Alice".to_string());
        
        let result = manager.process_template(&prompt, &vars).unwrap();
        assert_eq!(result, "Hello Alice!");
        
        // Test with default
        let empty_vars = HashMap::new();
        let result = manager.process_template(&prompt, &empty_vars).unwrap();
        assert_eq!(result, "Hello World!");
    }
}