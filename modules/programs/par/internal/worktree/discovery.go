package worktree

import (
	"os"
	"path/filepath"
	"strings"
)

// Worktree represents a Git worktree
type Worktree struct {
	Name   string `json:"name"`
	Path   string `json:"path"`
	Branch string `json:"branch"`
	Valid  bool   `json:"valid"`
	Errors []string `json:"errors,omitempty"`
}

// Discovery handles finding Git worktrees
type Discovery struct {
	searchPaths     []string
	excludePatterns []string
}

// NewDiscovery creates a new worktree discovery instance
func NewDiscovery(searchPaths, excludePatterns []string) *Discovery {
	return &Discovery{
		searchPaths:     searchPaths,
		excludePatterns: excludePatterns,
	}
}

// FindWorktrees discovers Git worktrees in the configured search paths
func (d *Discovery) FindWorktrees() ([]*Worktree, error) {
	var allWorktrees []*Worktree
	
	for _, searchPath := range d.searchPaths {
		worktrees, err := d.findInPath(searchPath)
		if err != nil {
			// Log error but continue with other paths
			continue
		}
		allWorktrees = append(allWorktrees, worktrees...)
	}
	
	return allWorktrees, nil
}

// findInPath finds worktrees in a specific path
func (d *Discovery) findInPath(searchPath string) ([]*Worktree, error) {
	// Expand home directory
	if strings.HasPrefix(searchPath, "~/") {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			return nil, err
		}
		searchPath = filepath.Join(homeDir, searchPath[2:])
	}
	
	// Check if path exists
	if _, err := os.Stat(searchPath); os.IsNotExist(err) {
		return []*Worktree{}, nil
	}
	
	var worktrees []*Worktree
	
	err := filepath.Walk(searchPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil // Skip problematic paths
		}
		
		// Skip if not a directory
		if !info.IsDir() {
			return nil
		}
		
		// Check exclude patterns
		if d.shouldExclude(path) {
			if info.IsDir() {
				return filepath.SkipDir
			}
			return nil
		}
		
		// Check if this is a Git repository
		if d.isGitRepository(path) {
			worktree := d.createWorktree(path)
			worktrees = append(worktrees, worktree)
			
			// Also check for Git worktrees
			gitWorktrees := d.findGitWorktrees(path)
			worktrees = append(worktrees, gitWorktrees...)
		}
		
		return nil
	})
	
	return worktrees, err
}

// shouldExclude checks if a path should be excluded based on patterns
func (d *Discovery) shouldExclude(path string) bool {
	for _, pattern := range d.excludePatterns {
		matched, err := filepath.Match(pattern, path)
		if err == nil && matched {
			return true
		}
		
		// Also check if any parent directory matches
		if strings.HasSuffix(pattern, "/*") {
			parentPattern := strings.TrimSuffix(pattern, "/*")
			// Check if path starts with the parent pattern followed by a path separator
			if strings.HasPrefix(path, parentPattern+string(filepath.Separator)) ||
				path == parentPattern {
				return true
			}
		}
	}
	return false
}

// isGitRepository checks if a directory is a Git repository
func (d *Discovery) isGitRepository(path string) bool {
	gitDir := filepath.Join(path, ".git")
	
	// Check for .git directory
	if info, err := os.Stat(gitDir); err == nil && info.IsDir() {
		return true
	}
	
	// Check for .git file (worktree case)
	if info, err := os.Stat(gitDir); err == nil && !info.IsDir() {
		return true
	}
	
	return false
}

// createWorktree creates a Worktree instance from a path
func (d *Discovery) createWorktree(path string) *Worktree {
	name := filepath.Base(path)
	branch := d.getCurrentBranch(path)
	
	worktree := &Worktree{
		Name:   name,
		Path:   path,
		Branch: branch,
		Valid:  true,
	}
	
	return worktree
}

// getCurrentBranch gets the current branch name for a Git repository
func (d *Discovery) getCurrentBranch(path string) string {
	// Try to read from .git/HEAD
	headFile := filepath.Join(path, ".git", "HEAD")
	
	// Handle worktree case - read .git file first
	gitFile := filepath.Join(path, ".git")
	if info, err := os.Stat(gitFile); err == nil && !info.IsDir() {
		content, err := os.ReadFile(gitFile)
		if err == nil {
			gitDirLine := strings.TrimSpace(string(content))
			if strings.HasPrefix(gitDirLine, "gitdir: ") {
				gitDir := strings.TrimPrefix(gitDirLine, "gitdir: ")
				if !filepath.IsAbs(gitDir) {
					gitDir = filepath.Join(path, gitDir)
				}
				headFile = filepath.Join(gitDir, "HEAD")
			}
		}
	}
	
	content, err := os.ReadFile(headFile)
	if err != nil {
		return "unknown"
	}
	
	head := strings.TrimSpace(string(content))
	
	// Parse branch from HEAD
	if strings.HasPrefix(head, "ref: refs/heads/") {
		return strings.TrimPrefix(head, "ref: refs/heads/")
	}
	
	// If it's a commit hash, return first 7 characters
	if len(head) >= 7 {
		return head[:7]
	}
	
	return "unknown"
}

// findGitWorktrees finds additional worktrees for a Git repository
func (d *Discovery) findGitWorktrees(repoPath string) []*Worktree {
	var worktrees []*Worktree
	
	// Look for worktrees in .git/worktrees/
	worktreesDir := filepath.Join(repoPath, ".git", "worktrees")
	
	entries, err := os.ReadDir(worktreesDir)
	if err != nil {
		return worktrees
	}
	
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		
		worktreePath := d.getWorktreePath(filepath.Join(worktreesDir, entry.Name()))
		if worktreePath != "" && worktreePath != repoPath {
			worktree := d.createWorktree(worktreePath)
			worktree.Name = entry.Name()
			worktrees = append(worktrees, worktree)
		}
	}
	
	return worktrees
}

// getWorktreePath reads the worktree path from a worktree config
func (d *Discovery) getWorktreePath(worktreeConfigDir string) string {
	gitdirFile := filepath.Join(worktreeConfigDir, "gitdir")
	
	content, err := os.ReadFile(gitdirFile)
	if err != nil {
		return ""
	}
	
	gitdir := strings.TrimSpace(string(content))
	
	// The gitdir points to the .git directory of the worktree
	// We want the parent directory
	return filepath.Dir(gitdir)
}