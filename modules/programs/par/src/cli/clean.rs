use anyhow::Result;
use clap::Args;
use std::path::Path;

use crate::config::Config;

#[derive(Debug, Args)]
pub struct CleanCommand {
    /// Clean all temporary files and results
    #[arg(long)]
    all: bool,

    /// Clean only failed runs
    #[arg(long)]
    failed: bool,
}

impl CleanCommand {
    pub async fn execute(self) -> Result<()> {
        let config = Config::load()?;
        let results_dir = &config.defaults.output_dir;

        if !results_dir.exists() {
            println!("No results directory found");
            return Ok(());
        }

        let mut removed_count = 0;

        if self.all {
            removed_count += self.clean_directory(results_dir)?;
        } else if self.failed {
            removed_count += self.clean_failed_runs(results_dir)?;
        } else {
            removed_count += self.clean_temp_files(results_dir)?;
        }

        println!("Cleaned {} files/directories", removed_count);
        Ok(())
    }

    fn clean_directory(&self, path: &Path) -> Result<usize> {
        let mut count = 0;
        
        if path.exists() {
            for entry in std::fs::read_dir(path)? {
                let entry = entry?;
                let path = entry.path();
                
                if path.is_dir() {
                    std::fs::remove_dir_all(&path)?;
                } else {
                    std::fs::remove_file(&path)?;
                }
                count += 1;
            }
        }
        
        Ok(count)
    }

    fn clean_failed_runs(&self, results_dir: &Path) -> Result<usize> {
        let mut count = 0;
        
        for entry in std::fs::read_dir(results_dir)? {
            let entry = entry?;
            let path = entry.path();
            
            if path.is_dir() {
                let summary_file = path.join("summary.json");
                if summary_file.exists() {
                    let content = std::fs::read_to_string(&summary_file)?;
                    if let Ok(summary) = serde_json::from_str::<serde_json::Value>(&content) {
                        if summary.get("status").and_then(|s| s.as_str()) == Some("failed") {
                            std::fs::remove_dir_all(&path)?;
                            count += 1;
                        }
                    }
                }
            }
        }
        
        Ok(count)
    }

    fn clean_temp_files(&self, results_dir: &Path) -> Result<usize> {
        let mut count = 0;
        
        for entry in std::fs::read_dir(results_dir)? {
            let entry = entry?;
            let path = entry.path();
            
            if path.extension().and_then(|s| s.to_str()) == Some("tmp") {
                std::fs::remove_file(&path)?;
                count += 1;
            }
        }
        
        Ok(count)
    }
}