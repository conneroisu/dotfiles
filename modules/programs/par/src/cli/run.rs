use anyhow::Result;
use clap::Args;
use std::collections::HashMap;
use std::path::PathBuf;
use std::time::Duration;

use crate::config::Config;
use crate::executor::{ExecutorPool, Job};
use crate::prompts::PromptManager;
use crate::results::{ResultAggregator, Reporter};
use crate::worktree::WorktreeManager;

#[derive(Debug, Args)]
pub struct RunCommand {
    /// Name of the prompt to run
    prompt_name: String,

    /// Number of parallel jobs
    #[arg(short, long, default_value_t = num_cpus::get())]
    jobs: usize,

    /// Filter worktrees by pattern
    #[arg(short, long)]
    worktrees: Option<String>,

    /// Specify custom directories
    #[arg(short, long)]
    directories: Vec<PathBuf>,

    /// Timeout per job (in seconds)
    #[arg(short, long, default_value_t = 1800)]
    timeout: u64,

    /// Output directory for results
    #[arg(short, long)]
    output: Option<PathBuf>,

    /// Show what would be executed without running
    #[arg(long)]
    dry_run: bool,

    /// Continue even if some jobs fail
    #[arg(long)]
    continue_on_failure: bool,

    /// Template variable substitution (key=value)
    #[arg(long, value_parser = parse_key_val::<String, String>)]
    template_vars: Vec<(String, String)>,

    /// Open each job in separate Ghostty window
    #[arg(long)]
    ghostty: bool,

    /// Show real-time terminal output
    #[arg(long)]
    terminal_output: bool,
}

fn parse_key_val<T, U>(s: &str) -> Result<(T, U), Box<dyn std::error::Error + Send + Sync + 'static>>
where
    T: std::str::FromStr,
    T::Err: std::error::Error + Send + Sync + 'static,
    U: std::str::FromStr,
    U::Err: std::error::Error + Send + Sync + 'static,
{
    let pos = s
        .find('=')
        .ok_or_else(|| format!("invalid KEY=value: no `=` found in `{}`", s))?;
    Ok((s[..pos].parse()?, s[pos + 1..].parse()?))
}

impl RunCommand {
    pub async fn execute(self) -> Result<()> {
        let config = Config::load()?;
        let prompt_manager = PromptManager::new()?;
        let worktree_manager = WorktreeManager::new(&config)?;

        let prompt = prompt_manager.get_prompt(&self.prompt_name)?
            .ok_or_else(|| anyhow::anyhow!("Prompt '{}' not found", self.prompt_name))?;

        let template_vars: HashMap<String, String> = self.template_vars.into_iter().collect();
        let processed_prompt = if prompt.template {
            prompt_manager.process_template(&prompt, &template_vars)?
        } else {
            prompt.content.clone()
        };

        let mut worktrees = if !self.directories.is_empty() {
            worktree_manager.from_directories(&self.directories)?
        } else {
            worktree_manager.discover()?
        };

        if let Some(pattern) = &self.worktrees {
            worktrees = worktree_manager.filter_by_pattern(worktrees, pattern)?;
        }

        if worktrees.is_empty() {
            anyhow::bail!("No worktrees found");
        }

        println!("Found {} worktrees", worktrees.len());

        if self.dry_run {
            println!("Would execute prompt '{}' on:", self.prompt_name);
            for worktree in &worktrees {
                println!("  - {}", worktree.path.display());
            }
            return Ok(());
        }

        let jobs: Vec<Job> = worktrees
            .into_iter()
            .map(|worktree| Job::new(
                worktree,
                processed_prompt.clone(),
                Duration::from_secs(self.timeout),
            ))
            .collect();

        let pool = ExecutorPool::new(
            self.jobs,
            self.ghostty,
            self.terminal_output,
            self.continue_on_failure,
        )?;

        let results = pool.execute(jobs).await?;

        let aggregator = ResultAggregator::new();
        let summary = aggregator.process_results(&results)?;

        let output_dir = self.output.unwrap_or_else(|| {
            config.defaults.output_dir.clone()
        });

        let reporter = Reporter::new(output_dir);
        reporter.generate_report(&summary).await?;

        println!("\n{}", summary);

        Ok(())
    }
}