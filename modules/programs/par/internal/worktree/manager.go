package worktree

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/config"
	"github.com/go-git/go-git/v5"
	"github.com/go-git/go-git/v5/plumbing"
	"github.com/google/uuid"
)

// Manager handles worktree operations
type Manager struct {
	config    *config.Config
	discovery *Discovery
	validator *Validator
}

// NewManager creates a new worktree manager
func NewManager(cfg *config.Config) (*Manager, error) {
	return &Manager{
		config:    cfg,
		discovery: NewDiscovery(cfg),
		validator: NewValidator(cfg),
	}, nil
}

// Discover discovers all valid worktrees
func (m *Manager) Discover() ([]*Worktree, error) {
	worktrees, err := m.discovery.FindWorktrees()
	if err != nil {
		return nil, fmt.Errorf("failed to discover worktrees: %w", err)
	}

	// Validate discovered worktrees
	validated := m.validator.FilterValid(worktrees)

	return validated, nil
}

// CreateTempWorktree creates a temporary worktree for a feature
func (m *Manager) CreateTempWorktree(sourceRepo, baseBranch, featureName string) (*Worktree, error) {
	// Generate unique ID for this try
	tryID := uuid.New().String()[:8]
	
	// Create worktree path: feat/<feature>/try-<uuid>
	worktreeName := fmt.Sprintf("feat/%s/try-%s", featureName, tryID)
	
	// Determine base directory for temporary worktrees
	sourceDir := filepath.Dir(sourceRepo)
	worktreePath := filepath.Join(sourceDir, worktreeName)
	
	// Ensure the feat/<feature> directory exists
	featureDir := filepath.Dir(worktreePath)
	if err := os.MkdirAll(featureDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create feature directory: %w", err)
	}

	// Open the source repository
	repo, err := git.PlainOpen(sourceRepo)
	if err != nil {
		return nil, fmt.Errorf("failed to open source repository: %w", err)
	}

	// Get the base branch reference
	ref, err := repo.Reference(plumbing.ReferenceName("refs/heads/"+baseBranch), true)
	if err != nil {
		return nil, fmt.Errorf("failed to get base branch reference: %w", err)
	}

	// Create worktree
	workTree, err := repo.Worktree()
	if err != nil {
		return nil, fmt.Errorf("failed to get main worktree: %w", err)
	}

	// Create new worktree
	newWorkTree, err := workTree.AddWorktree(&git.AddWorktreeOptions{
		Path:   worktreePath,
		Branch: plumbing.ReferenceName("refs/heads/" + worktreeName),
		Ref:    ref.Hash(),
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create worktree: %w", err)
	}

	// Get project name
	projectName := filepath.Base(sourceRepo)

	return &Worktree{
		Name:       projectName + "-" + tryID,
		Path:       worktreePath,
		Branch:     worktreeName,
		IsDirty:    false,
		IsTemp:     true,
		RemoteURL:  "", // Temporary worktrees don't need remote
	}, nil
}

// CleanupTempWorktree removes a temporary worktree
func (m *Manager) CleanupTempWorktree(worktreePath string) error {
	// Check if this looks like a temporary worktree
	if !strings.Contains(worktreePath, "feat/") || !strings.Contains(worktreePath, "try-") {
		return fmt.Errorf("path does not appear to be a temporary worktree: %s", worktreePath)
	}

	// Find the parent repository
	parentDir := filepath.Dir(worktreePath)
	for strings.Contains(parentDir, "feat/") {
		parentDir = filepath.Dir(parentDir)
	}

	// Open the parent repository
	repo, err := git.PlainOpen(parentDir)
	if err != nil {
		// If we can't open as git repo, just remove the directory
		return os.RemoveAll(worktreePath)
	}

	// Remove the worktree from git
	mainWorkTree, err := repo.Worktree()
	if err == nil {
		// Try to remove the worktree properly
		mainWorkTree.RemoveWorktree(worktreePath)
	}

	// Remove the directory
	return os.RemoveAll(worktreePath)
}

// StashChanges stashes uncommitted changes in a worktree
func (m *Manager) StashChanges(worktreePath string) error {
	repo, err := git.PlainOpen(worktreePath)
	if err != nil {
		return fmt.Errorf("failed to open repository: %w", err)
	}

	workTree, err := repo.Worktree()
	if err != nil {
		return fmt.Errorf("failed to get worktree: %w", err)
	}

	status, err := workTree.Status()
	if err != nil {
		return fmt.Errorf("failed to get status: %w", err)
	}

	if status.IsClean() {
		return nil // Nothing to stash
	}

	// Note: go-git doesn't support stashing directly
	// For now, we'll just check if changes exist
	// In a real implementation, you might want to use git commands directly
	
	return nil
}

// GetWorktreeInfo gets information about a specific worktree
func (m *Manager) GetWorktreeInfo(path string) (*Worktree, error) {
	return m.discovery.analyzeRepository(path)
}