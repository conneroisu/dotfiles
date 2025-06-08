// Package worktree handles Git worktree discovery and management
package worktree

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/config"
	"github.com/go-git/go-git/v5"
)

// Discovery handles worktree discovery
type Discovery struct {
	config *config.Config
}

// NewDiscovery creates a new worktree discovery instance
func NewDiscovery(cfg *config.Config) *Discovery {
	return &Discovery{
		config: cfg,
	}
}

// FindWorktrees discovers all valid Git worktrees in search paths
func (d *Discovery) FindWorktrees() ([]*Worktree, error) {
	var worktrees []*Worktree

	for _, searchPath := range d.config.Worktrees.SearchPaths {
		expandedPath := expandPath(searchPath)
		
		// Check if path exists
		if _, err := os.Stat(expandedPath); os.IsNotExist(err) {
			continue
		}

		found, err := d.scanDirectory(expandedPath)
		if err != nil {
			// Log error but continue with other paths
			continue
		}

		worktrees = append(worktrees, found...)
	}

	// Filter out excluded patterns
	filtered := d.filterExcluded(worktrees)

	return filtered, nil
}

// scanDirectory recursively scans a directory for Git repositories
func (d *Discovery) scanDirectory(path string) ([]*Worktree, error) {
	var worktrees []*Worktree

	// Check if this directory is a Git repository
	if d.isGitRepository(path) {
		wt, err := d.analyzeRepository(path)
		if err == nil {
			worktrees = append(worktrees, wt)
		}
		// Don't scan subdirectories of Git repos
		return worktrees, nil
	}

	// Scan subdirectories
	entries, err := os.ReadDir(path)
	if err != nil {
		return nil, err
	}

	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}

		// Skip hidden directories and common non-project directories
		if strings.HasPrefix(entry.Name(), ".") {
			continue
		}

		subPath := filepath.Join(path, entry.Name())
		found, err := d.scanDirectory(subPath)
		if err != nil {
			// Continue with other directories
			continue
		}

		worktrees = append(worktrees, found...)
	}

	return worktrees, nil
}

// isGitRepository checks if a directory contains a Git repository
func (d *Discovery) isGitRepository(path string) bool {
	gitPath := filepath.Join(path, ".git")
	_, err := os.Stat(gitPath)
	return err == nil
}

// analyzeRepository analyzes a Git repository and creates a Worktree
func (d *Discovery) analyzeRepository(path string) (*Worktree, error) {
	repo, err := git.PlainOpen(path)
	if err != nil {
		return nil, fmt.Errorf("failed to open repository: %w", err)
	}

	// Get current branch
	head, err := repo.Head()
	if err != nil {
		return nil, fmt.Errorf("failed to get HEAD: %w", err)
	}

	branchName := "detached"
	if head.Name().IsBranch() {
		branchName = head.Name().Short()
	}

	// Check working tree status
	workTree, err := repo.Worktree()
	if err != nil {
		return nil, fmt.Errorf("failed to get worktree: %w", err)
	}

	status, err := workTree.Status()
	if err != nil {
		return nil, fmt.Errorf("failed to get status: %w", err)
	}

	// Determine project name from directory name
	projectName := filepath.Base(path)

	// Get remote URL if available
	remoteURL := ""
	remotes, err := repo.Remotes()
	if err == nil && len(remotes) > 0 {
		for _, remote := range remotes {
			if remote.Config().Name == "origin" {
				if len(remote.Config().URLs) > 0 {
					remoteURL = remote.Config().URLs[0]
				}
				break
			}
		}
	}

	return &Worktree{
		Name:      projectName,
		Path:      path,
		Branch:    branchName,
		IsDirty:   !status.IsClean(),
		RemoteURL: remoteURL,
	}, nil
}

// filterExcluded filters out worktrees matching exclude patterns
func (d *Discovery) filterExcluded(worktrees []*Worktree) []*Worktree {
	var filtered []*Worktree

	for _, wt := range worktrees {
		excluded := false
		for _, pattern := range d.config.Worktrees.ExcludePatterns {
			if d.matchesPattern(wt.Path, pattern) {
				excluded = true
				break
			}
		}

		if !excluded {
			filtered = append(filtered, wt)
		}
	}

	return filtered
}

// matchesPattern checks if a path matches a glob-like pattern
func (d *Discovery) matchesPattern(path, pattern string) bool {
	// Simple glob matching - could be enhanced with filepath.Match
	return strings.Contains(path, strings.ReplaceAll(pattern, "*", ""))
}

// expandPath expands ~ to home directory
func expandPath(path string) string {
	if len(path) > 0 && path[0] == '~' {
		home, err := os.UserHomeDir()
		if err != nil {
			return path
		}
		return filepath.Join(home, path[1:])
	}
	return path
}