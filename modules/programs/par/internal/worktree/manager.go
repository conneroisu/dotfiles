package worktree

import (
	"fmt"
	"os/exec"
	"path/filepath"
	"strings"
)

// Manager handles worktree operations and state management
type Manager struct {
	validator *Validator
}

// NewManager creates a new worktree manager
func NewManager() *Manager {
	return &Manager{
		validator: NewValidator(),
	}
}

// PrepareWorktree prepares a worktree for par execution
func (m *Manager) PrepareWorktree(worktree *Worktree) error {
	// Validate the worktree first
	m.validator.ValidateWorktree(worktree)
	if !worktree.Valid {
		return fmt.Errorf("worktree validation failed: %s", strings.Join(worktree.Errors, ", "))
	}
	
	// Stash any uncommitted changes if needed
	if err := m.stashChanges(worktree.Path); err != nil {
		return fmt.Errorf("failed to stash changes: %w", err)
	}
	
	return nil
}

// CleanupWorktree cleans up a worktree after par execution
func (m *Manager) CleanupWorktree(worktree *Worktree, restoreChanges bool) error {
	if restoreChanges {
		// Restore stashed changes if any
		if err := m.restoreStash(worktree.Path); err != nil {
			// Log but don't fail - stash might not exist
		}
	}
	
	return nil
}

// FilterByPattern filters worktrees by a glob pattern
func (m *Manager) FilterByPattern(worktrees []*Worktree, pattern string) ([]*Worktree, error) {
	if pattern == "" {
		return worktrees, nil
	}
	
	var filtered []*Worktree
	
	for _, worktree := range worktrees {
		// Check if name or path matches the pattern
		nameMatched, err := filepath.Match(pattern, worktree.Name)
		if err != nil {
			return nil, fmt.Errorf("invalid pattern '%s': %w", pattern, err)
		}
		
		pathMatched, err := filepath.Match(pattern, worktree.Path)
		if err != nil {
			return nil, fmt.Errorf("invalid pattern '%s': %w", pattern, err)
		}
		
		branchMatched, err := filepath.Match(pattern, worktree.Branch)
		if err != nil {
			return nil, fmt.Errorf("invalid pattern '%s': %w", pattern, err)
		}
		
		if nameMatched || pathMatched || branchMatched {
			filtered = append(filtered, worktree)
		}
	}
	
	return filtered, nil
}

// GetWorktreeInfo retrieves detailed information about a worktree
func (m *Manager) GetWorktreeInfo(worktree *Worktree) (*WorktreeInfo, error) {
	info := &WorktreeInfo{
		Worktree: worktree,
	}
	
	// Get commit hash
	if hash, err := m.getCurrentCommit(worktree.Path); err == nil {
		info.CommitHash = hash
	}
	
	// Get remote information
	if remote, err := m.getRemoteOrigin(worktree.Path); err == nil {
		info.RemoteOrigin = remote
	}
	
	// Check if working directory is clean
	info.IsClean = m.isWorkingDirectoryClean(worktree.Path)
	
	return info, nil
}

// WorktreeInfo contains detailed information about a worktree
type WorktreeInfo struct {
	Worktree     *Worktree `json:"worktree"`
	CommitHash   string    `json:"commit_hash"`
	RemoteOrigin string    `json:"remote_origin"`
	IsClean      bool      `json:"is_clean"`
}

// stashChanges stashes uncommitted changes in a Git repository
func (m *Manager) stashChanges(path string) error {
	// Check if there are changes to stash
	if m.isWorkingDirectoryClean(path) {
		return nil
	}
	
	cmd := exec.Command("git", "stash", "push", "-m", "par: automated stash before execution")
	cmd.Dir = path
	
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("git stash failed: %w", err)
	}
	
	return nil
}

// restoreStash restores the most recent stash
func (m *Manager) restoreStash(path string) error {
	// Check if there are any stashes
	cmd := exec.Command("git", "stash", "list")
	cmd.Dir = path
	
	output, err := cmd.Output()
	if err != nil || len(strings.TrimSpace(string(output))) == 0 {
		return nil // No stashes to restore
	}
	
	// Check if the top stash was created by par
	lines := strings.Split(strings.TrimSpace(string(output)), "\n")
	if len(lines) > 0 && strings.Contains(lines[0], "par: automated stash") {
		cmd = exec.Command("git", "stash", "pop")
		cmd.Dir = path
		
		if err := cmd.Run(); err != nil {
			return fmt.Errorf("git stash pop failed: %w", err)
		}
	}
	
	return nil
}

// getCurrentCommit gets the current commit hash
func (m *Manager) getCurrentCommit(path string) (string, error) {
	cmd := exec.Command("git", "rev-parse", "HEAD")
	cmd.Dir = path
	
	output, err := cmd.Output()
	if err != nil {
		return "", err
	}
	
	return strings.TrimSpace(string(output)), nil
}

// getRemoteOrigin gets the remote origin URL
func (m *Manager) getRemoteOrigin(path string) (string, error) {
	cmd := exec.Command("git", "remote", "get-url", "origin")
	cmd.Dir = path
	
	output, err := cmd.Output()
	if err != nil {
		return "", err
	}
	
	return strings.TrimSpace(string(output)), nil
}

// isWorkingDirectoryClean checks if the working directory is clean
func (m *Manager) isWorkingDirectoryClean(path string) bool {
	cmd := exec.Command("git", "status", "--porcelain")
	cmd.Dir = path
	
	output, err := cmd.Output()
	if err != nil {
		return false
	}
	
	return len(strings.TrimSpace(string(output))) == 0
}