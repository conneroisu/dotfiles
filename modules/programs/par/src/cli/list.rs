use anyhow::Result;
use clap::{Args, ValueEnum};
use tabled::{Table, Tabled};

use crate::config::Config;
use crate::prompts::PromptManager;
use crate::worktree::WorktreeManager;

#[derive(Debug, Args)]
pub struct ListCommand {
    /// What to list
    #[arg(value_enum, default_value = "all")]
    target: ListTarget,
}

#[derive(Debug, Clone, ValueEnum)]
enum ListTarget {
    All,
    Prompts,
    Worktrees,
}

#[derive(Tabled)]
struct PromptInfo {
    name: String,
    #[tabled(rename = "Is Template")]
    is_template: String,
    description: String,
    created: String,
}

#[derive(Tabled)]
struct WorktreeInfo {
    path: String,
    branch: String,
    clean: String,
}

impl ListCommand {
    pub async fn execute(self) -> Result<()> {
        match self.target {
            ListTarget::All => {
                self.list_prompts()?;
                println!();
                self.list_worktrees()?;
            }
            ListTarget::Prompts => self.list_prompts()?,
            ListTarget::Worktrees => self.list_worktrees()?,
        }
        Ok(())
    }

    fn list_prompts(&self) -> Result<()> {
        let manager = PromptManager::new()?;
        let prompts = manager.list_prompts()?;

        if prompts.is_empty() {
            println!("No prompts found");
            return Ok(());
        }

        println!("Available Prompts:");
        let prompt_infos: Vec<PromptInfo> = prompts
            .into_iter()
            .map(|p| PromptInfo {
                name: p.name,
                is_template: if p.template { "Yes" } else { "No" }.to_string(),
                description: p.description.unwrap_or_else(|| "-".to_string()),
                created: p.created.format("%Y-%m-%d %H:%M").to_string(),
            })
            .collect();

        let table = Table::new(prompt_infos);
        println!("{}", table);

        Ok(())
    }

    fn list_worktrees(&self) -> Result<()> {
        let config = Config::load()?;
        let manager = WorktreeManager::new(&config)?;
        let worktrees = manager.discover()?;

        if worktrees.is_empty() {
            println!("No worktrees found");
            return Ok(());
        }

        println!("Discovered Worktrees:");
        let worktree_infos: Vec<WorktreeInfo> = worktrees
            .into_iter()
            .map(|w| WorktreeInfo {
                path: w.path.display().to_string(),
                branch: w.branch.unwrap_or_else(|| "-".to_string()),
                clean: if w.is_clean { "Yes" } else { "No" }.to_string(),
            })
            .collect();

        let table = Table::new(worktree_infos);
        println!("{}", table);

        Ok(())
    }
}