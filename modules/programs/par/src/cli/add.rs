use anyhow::Result;
use clap::Args;
use std::path::PathBuf;

use crate::prompts::{Prompt, PromptManager};

#[derive(Debug, Args)]
pub struct AddCommand {
    /// Name for the prompt
    #[arg(short, long)]
    name: Option<String>,

    /// File containing the prompt content
    #[arg(short, long)]
    file: Option<PathBuf>,

    /// Create a template prompt with variables
    #[arg(short, long)]
    template: bool,

    /// Description of the prompt
    #[arg(short, long)]
    description: Option<String>,
}

impl AddCommand {
    pub async fn execute(self) -> Result<()> {
        let manager = PromptManager::new()?;

        let content = if let Some(file) = self.file {
            std::fs::read_to_string(file)?
        } else {
            let editor = std::env::var("EDITOR").unwrap_or_else(|_| "vim".to_string());
            let temp_file = tempfile::NamedTempFile::new()?;
            let temp_path = temp_file.path().to_owned();

            std::process::Command::new(&editor)
                .arg(&temp_path)
                .status()?;

            std::fs::read_to_string(temp_path)?
        };

        let name = self.name.unwrap_or_else(|| {
            println!("Enter prompt name:");
            let mut name = String::new();
            std::io::stdin().read_line(&mut name).unwrap();
            name.trim().to_string()
        });

        let prompt = Prompt::new(
            name.clone(),
            content,
            self.description,
            self.template,
        );

        manager.add_prompt(prompt)?;
        println!("Added prompt: {}", name);

        Ok(())
    }
}