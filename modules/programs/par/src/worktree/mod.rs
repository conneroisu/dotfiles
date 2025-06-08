use gix::ThreadSafeRepository;
use std::path::{Path, PathBuf};

use crate::config::{Config, WorktreeSettings};
use crate::error::{ParError, Result};

#[derive(Debug, Clone)]
pub struct Worktree {
    pub path: PathBuf,
    pub branch: Option<String>,
    pub is_clean: bool,
    pub remote_url: Option<String>,
}

pub struct WorktreeManager {
    settings: WorktreeSettings,
}

impl WorktreeManager {
    pub fn new(config: &Config) -> Result<Self> {
        Ok(Self {
            settings: config.worktrees.clone(),
        })
    }
    
    pub fn discover(&self) -> Result<Vec<Worktree>> {
        let mut worktrees = Vec::new();
        
        for search_path in &self.settings.search_paths {
            if search_path.exists() {
                self.discover_in_path(search_path, &mut worktrees)?;
            }
        }
        
        Ok(worktrees)
    }
    
    pub fn from_directories(&self, paths: &[PathBuf]) -> Result<Vec<Worktree>> {
        let mut worktrees = Vec::new();
        
        for path in paths {
            if let Ok(worktree) = self.validate_worktree(path) {
                worktrees.push(worktree);
            }
        }
        
        Ok(worktrees)
    }
    
    pub fn filter_by_pattern(&self, worktrees: Vec<Worktree>, pattern: &str) -> Result<Vec<Worktree>> {
        let glob_pattern = glob::Pattern::new(pattern)
            .map_err(|e| ParError::Worktree(format!("Invalid pattern: {}", e)))?;
        
        Ok(worktrees
            .into_iter()
            .filter(|w| {
                w.path.to_string_lossy().contains(pattern) ||
                glob_pattern.matches(&w.path.to_string_lossy()) ||
                w.branch.as_ref().map_or(false, |b| b.contains(pattern))
            })
            .collect())
    }
    
    pub fn create_temporary(&self, base_branch: &str) -> Result<Worktree> {
        // Find a main repository first
        let main_repo = self.find_main_repository()?;
        let temp_name = format!("par-temp-{}", uuid::Uuid::new_v4());
        let temp_path = main_repo.parent()
            .ok_or_else(|| ParError::Worktree("Invalid repository path".to_string()))?
            .join(&temp_name);
        
        // Use gix to create a worktree
        let repo = ThreadSafeRepository::open(&main_repo)
            .map_err(|e| ParError::Git(format!("Failed to open repository: {}", e)))?;
        
        // Create worktree using git command for now (gix worktree support is limited)
        std::process::Command::new("git")
            .args(&["worktree", "add", "-b", &temp_name, temp_path.to_str().unwrap(), base_branch])
            .current_dir(&main_repo)
            .output()
            .map_err(|e| ParError::Git(format!("Failed to create worktree: {}", e)))?;
        
        self.validate_worktree(&temp_path)
    }
    
    pub fn cleanup_temporary(&self, worktree: &Worktree) -> Result<()> {
        if !worktree.path.to_string_lossy().contains("par-temp-") {
            return Err(ParError::Worktree("Not a temporary worktree".to_string()));
        }
        
        // Remove worktree
        std::process::Command::new("git")
            .args(&["worktree", "remove", worktree.path.to_str().unwrap()])
            .output()
            .map_err(|e| ParError::Git(format!("Failed to remove worktree: {}", e)))?;
        
        Ok(())
    }
    
    fn discover_in_path(&self, path: &Path, worktrees: &mut Vec<Worktree>) -> Result<()> {
        if self.should_exclude(path) {
            return Ok(());
        }
        
        // Check if this directory is a git repository
        if path.join(".git").exists() {
            if let Ok(worktree) = self.validate_worktree(path) {
                worktrees.push(worktree);
            }
        }
        
        // Recursively search subdirectories
        if let Ok(entries) = std::fs::read_dir(path) {
            for entry in entries {
                if let Ok(entry) = entry {
                    let entry_path = entry.path();
                    if entry_path.is_dir() {
                        self.discover_in_path(&entry_path, worktrees)?;
                    }
                }
            }
        }
        
        Ok(())
    }
    
    fn validate_worktree(&self, path: &Path) -> Result<Worktree> {
        let repo = ThreadSafeRepository::open(path)
            .map_err(|e| ParError::Git(format!("Failed to open repository: {}", e)))?;
        
        let repo = repo.to_thread_local();
        
        // Get current branch
        let branch = repo.head_name()
            .ok()
            .and_then(|name| name.map(|n| n.as_bstr().to_string()));
        
        // Check if working directory is clean
        let is_clean = self.is_working_directory_clean(&repo)?;
        
        // Get remote URL
        let remote_url = repo.find_default_remote(gix::remote::Direction::Fetch)
            .ok()
            .flatten()
            .and_then(|remote| {
                remote.url(gix::remote::Direction::Fetch)
                    .map(|url| url.to_bstring().to_string())
            });
        
        Ok(Worktree {
            path: path.to_path_buf(),
            branch,
            is_clean,
            remote_url,
        })
    }
    
    fn is_working_directory_clean(&self, repo: &gix::Repository) -> Result<bool> {
        // Check for uncommitted changes
        let mut status_iter = repo.status_iter()
            .map_err(|e| ParError::Git(format!("Failed to get status: {}", e)))?;
        
        // If there are any status entries, the working directory is not clean
        Ok(status_iter.next().is_none())
    }
    
    fn should_exclude(&self, path: &Path) -> bool {
        let path_str = path.to_string_lossy();
        
        for pattern in &self.settings.exclude_patterns {
            if let Ok(glob_pattern) = glob::Pattern::new(pattern) {
                if glob_pattern.matches(&path_str) {
                    return true;
                }
            }
        }
        
        false
    }
    
    fn find_main_repository(&self) -> Result<PathBuf> {
        // Try to find a repository in the search paths
        for search_path in &self.settings.search_paths {
            if let Ok(entries) = std::fs::read_dir(search_path) {
                for entry in entries {
                    if let Ok(entry) = entry {
                        let path = entry.path();
                        if path.join(".git").exists() {
                            return Ok(path);
                        }
                    }
                }
            }
        }
        
        Err(ParError::Worktree("No git repository found".to_string()))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;
    
    #[test]
    fn test_should_exclude() {
        let config = Config::default();
        let manager = WorktreeManager::new(&config).unwrap();
        
        assert!(manager.should_exclude(Path::new("/home/user/project/node_modules/package")));
        assert!(manager.should_exclude(Path::new("/home/user/project/.git/objects")));
        assert!(manager.should_exclude(Path::new("/home/user/project/target/debug")));
        assert!(!manager.should_exclude(Path::new("/home/user/project/src")));
    }
}