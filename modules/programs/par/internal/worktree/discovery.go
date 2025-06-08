package worktree

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/go-git/go-git/v5"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/config"
)

type DiscoveryOptions struct {
	SearchPaths     []string
	ExcludePatterns []string
	MaxDepth        int
}

type Discoverer struct {
	options DiscoveryOptions
}

func NewDiscoverer() *Discoverer {
	cfg := config.Get()
	
	var searchPaths []string
	for _, path := range cfg.Worktrees.SearchPaths {
		searchPaths = append(searchPaths, config.ExpandPath(path))
	}
	
	return &Discoverer{
		options: DiscoveryOptions{
			SearchPaths:     searchPaths,
			ExcludePatterns: cfg.Worktrees.ExcludePatterns,
			MaxDepth:        5, // Reasonable default to avoid infinite recursion
		},
	}
}

func (d *Discoverer) FindWorktrees() ([]*Worktree, error) {
	var allWorktrees []*Worktree
	
	for _, searchPath := range d.options.SearchPaths {
		worktrees, err := d.findWorktreesInPath(searchPath, 0)
		if err != nil {
			// Log error but continue with other paths
			fmt.Printf("Warning: failed to search path %s: %v\n", searchPath, err)
			continue
		}
		allWorktrees = append(allWorktrees, worktrees...)
	}
	
	return d.filterWorktrees(allWorktrees), nil
}

func (d *Discoverer) findWorktreesInPath(searchPath string, depth int) ([]*Worktree, error) {
	if depth > d.options.MaxDepth {
		return nil, nil
	}
	
	var worktrees []*Worktree
	
	// Check if this path itself is a git repository
	if worktree := d.checkGitRepository(searchPath); worktree != nil {
		worktrees = append(worktrees, worktree)
	}
	
	// Recursively search subdirectories
	entries, err := os.ReadDir(searchPath)
	if err != nil {
		return worktrees, nil // Return what we found so far
	}
	
	for _, entry := range entries {
		if !entry.IsDir() {
			continue
		}
		
		subPath := filepath.Join(searchPath, entry.Name())
		
		// Skip if matches exclude patterns
		if d.shouldExclude(subPath) {
			continue
		}
		
		// Skip .git directories but not nested repos
		if entry.Name() == ".git" {
			continue
		}
		
		subWorktrees, err := d.findWorktreesInPath(subPath, depth+1)
		if err != nil {
			continue // Skip directories we can't read
		}
		
		worktrees = append(worktrees, subWorktrees...)
	}
	
	return worktrees, nil
}

func (d *Discoverer) checkGitRepository(path string) *Worktree {
	// Try to open as git repository
	repo, err := git.PlainOpen(path)
	if err != nil {
		return nil
	}
	
	// Get current HEAD reference
	head, err := repo.Head()
	if err != nil {
		return nil
	}
	
	// Get working tree
	workTree, err := repo.Worktree()
	if err != nil {
		return nil
	}
	
	// Check if working tree is dirty
	status, err := workTree.Status()
	isDirty := err == nil && !status.IsClean()
	
	// Get remote URL (if any)
	remotes, err := repo.Remotes()
	var remoteURL string
	if err == nil && len(remotes) > 0 {
		config := remotes[0].Config()
		if len(config.URLs) > 0 {
			remoteURL = config.URLs[0]
		}
	}
	
	// Extract project name from path or remote URL
	projectName := d.extractProjectName(path, remoteURL)
	
	worktree := &Worktree{
		ID:          generateID(path),
		Name:        filepath.Base(path),
		Path:        path,
		Branch:      head.Name().Short(),
		RemoteURL:   remoteURL,
		LastCommit:  head.Hash().String(),
		IsDirty:     isDirty,
		IsValid:     true, // Will be validated later
		ProjectName: projectName,
	}
	
	return worktree
}

func (d *Discoverer) shouldExclude(path string) bool {
	for _, pattern := range d.options.ExcludePatterns {
		matched, err := filepath.Match(pattern, path)
		if err == nil && matched {
			return true
		}
		
		// Also check if any parent directory matches
		if strings.Contains(path, strings.Replace(pattern, "*", "", -1)) {
			return true
		}
	}
	return false
}

func (d *Discoverer) filterWorktrees(worktrees []*Worktree) []*Worktree {
	// Remove duplicates based on path
	seen := make(map[string]bool)
	var filtered []*Worktree
	
	for _, wt := range worktrees {
		if !seen[wt.Path] {
			seen[wt.Path] = true
			filtered = append(filtered, wt)
		}
	}
	
	return filtered
}

func (d *Discoverer) extractProjectName(path, remoteURL string) string {
	// Try to extract from remote URL first
	if remoteURL != "" {
		parts := strings.Split(remoteURL, "/")
		if len(parts) > 0 {
			name := parts[len(parts)-1]
			// Remove .git suffix if present
			if strings.HasSuffix(name, ".git") {
				name = name[:len(name)-4]
			}
			return name
		}
	}
	
	// Fall back to directory name
	return filepath.Base(path)
}

func generateID(path string) string {
	// Simple hash-like ID generation based on path
	hash := 0
	for _, char := range path {
		hash = hash*31 + int(char)
	}
	if hash < 0 {
		hash = -hash
	}
	return fmt.Sprintf("wt-%d", hash)
}