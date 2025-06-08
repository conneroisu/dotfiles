package worktree

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/go-git/go-git/v5"
)

type Manager struct {
	discoverer *Discoverer
	validator  *Validator
}

func NewManager() *Manager {
	return &Manager{
		discoverer: NewDiscoverer(),
		validator:  NewValidator(false),
	}
}

func (m *Manager) DiscoverAndValidate() ([]*Worktree, map[string]*ValidationResult, error) {
	// Discover all worktrees
	worktrees, err := m.discoverer.FindWorktrees()
	if err != nil {
		return nil, nil, fmt.Errorf("failed to discover worktrees: %w", err)
	}
	
	// Validate them
	validWorktrees, results := m.validator.ValidateWorktrees(worktrees)
	
	return validWorktrees, results, nil
}

func (m *Manager) CreateWorktree(repoPath, branchName, worktreePath string) (*Worktree, error) {
	// Open the repository
	repo, err := git.PlainOpen(repoPath)
	if err != nil {
		return nil, fmt.Errorf("failed to open repository: %w", err)
	}
	
	// Create the worktree directory
	if err := os.MkdirAll(worktreePath, 0755); err != nil {
		return nil, fmt.Errorf("failed to create worktree directory: %w", err)
	}
	
	// Note: This is a simplified implementation
	// Real worktree creation would require git command line
	_ = repo
	
	// Note: go-git doesn't support worktree creation directly
	// This would need to be implemented using git command line or different approach
	// For now, we'll create a placeholder implementation
	if err := os.MkdirAll(worktreePath, 0755); err != nil {
		return nil, fmt.Errorf("failed to create worktree directory: %w", err)
	}
	
	// Create our Worktree representation
	wt := &Worktree{
		ID:          generateID(worktreePath),
		Name:        filepath.Base(worktreePath),
		Path:        worktreePath,
		Branch:      branchName,
		IsDirty:     false,
		IsValid:     true,
		ProjectName: m.extractProjectName(repoPath),
	}
	
	return wt, nil
}

func (m *Manager) RemoveWorktree(worktreePath string) error {
	// Find the main repository
	repo, err := m.findMainRepository(worktreePath)
	if err != nil {
		return fmt.Errorf("failed to find main repository: %w", err)
	}
	
	// Note: Simplified implementation
	_ = repo
	
	// Note: go-git doesn't support worktree removal directly
	// This would need to be implemented using git command line
	// For now, we'll just remove the directory
	
	// Remove the directory
	if err := os.RemoveAll(worktreePath); err != nil {
		return fmt.Errorf("failed to remove worktree directory: %w", err)
	}
	
	return nil
}

func (m *Manager) CleanupWorktrees(worktrees []*Worktree) error {
	for _, wt := range worktrees {
		if !wt.IsValid {
			if err := m.RemoveWorktree(wt.Path); err != nil {
				fmt.Printf("Warning: failed to cleanup worktree %s: %v\n", wt.Path, err)
			}
		}
	}
	return nil
}

func (m *Manager) GetWorktreeInfo(path string) (*Worktree, error) {
	// Try to open as git repository
	repo, err := git.PlainOpen(path)
	if err != nil {
		return nil, fmt.Errorf("not a git repository: %w", err)
	}
	
	// Get current HEAD reference
	head, err := repo.Head()
	if err != nil {
		return nil, fmt.Errorf("failed to get HEAD: %w", err)
	}
	
	// Get working tree status
	workTree, err := repo.Worktree()
	if err != nil {
		return nil, fmt.Errorf("failed to get worktree: %w", err)
	}
	
	status, err := workTree.Status()
	isDirty := err == nil && !status.IsClean()
	
	// Get remote URL
	remotes, err := repo.Remotes()
	var remoteURL string
	if err == nil && len(remotes) > 0 {
		config := remotes[0].Config()
		if len(config.URLs) > 0 {
			remoteURL = config.URLs[0]
		}
	}
	
	worktree := &Worktree{
		ID:          generateID(path),
		Name:        filepath.Base(path),
		Path:        path,
		Branch:      head.Name().Short(),
		RemoteURL:   remoteURL,
		LastCommit:  head.Hash().String(),
		IsDirty:     isDirty,
		IsValid:     true,
		ProjectName: m.extractProjectName(path),
	}
	
	return worktree, nil
}

func (m *Manager) findMainRepository(worktreePath string) (*git.Repository, error) {
	// Look for .git file that points to the main repository
	gitFile := filepath.Join(worktreePath, ".git")
	
	if _, err := os.Stat(gitFile); err != nil {
		return nil, fmt.Errorf(".git file not found: %w", err)
	}
	
	// Try to open the repository
	repo, err := git.PlainOpen(worktreePath)
	if err != nil {
		return nil, fmt.Errorf("failed to open repository: %w", err)
	}
	
	return repo, nil
}

func (m *Manager) extractProjectName(path string) string {
	// Extract project name from path
	return filepath.Base(path)
}

func (m *Manager) SetValidator(strict bool) {
	m.validator = NewValidator(strict)
}

func (m *Manager) GetDiscoverer() *Discoverer {
	return m.discoverer
}

func (m *Manager) GetValidator() *Validator {
	return m.validator
}