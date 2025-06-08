use anyhow::Result;
use clap::{Parser, Subcommand};

mod add;
mod clean;
mod list;
mod run;

use add::AddCommand;
use clean::CleanCommand;
use list::ListCommand;
use run::RunCommand;

#[derive(Debug, Parser)]
#[command(author, version, about, long_about = None)]
pub struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Debug, Subcommand)]
enum Commands {
    /// Add a new prompt to the library
    Add(AddCommand),

    /// Run a prompt across multiple worktrees
    Run(RunCommand),

    /// List available prompts and discovered worktrees
    List(ListCommand),

    /// Clean up temporary files and failed runs
    Clean(CleanCommand),
}

impl Cli {
    pub async fn run(self) -> Result<()> {
        match self.command {
            Commands::Add(cmd) => cmd.execute().await,
            Commands::Run(cmd) => cmd.execute().await,
            Commands::List(cmd) => cmd.execute().await,
            Commands::Clean(cmd) => cmd.execute().await,
        }
    }
}