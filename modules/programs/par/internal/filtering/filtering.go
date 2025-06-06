package filtering

import (
	"path/filepath"
	"strings"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/interfaces"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/worktree"
)

// WorktreeFilter implements the WorktreeFilter interface
type WorktreeFilter struct {
	fileSystem interfaces.FileSystem
}

// NewWorktreeFilter creates a new worktree filter with the provided file system
func NewWorktreeFilter(fs interfaces.FileSystem) *WorktreeFilter {
	return &WorktreeFilter{
		fileSystem: fs,
	}
}

// NewDefaultWorktreeFilter creates a filter with real file system implementation
func NewDefaultWorktreeFilter() *WorktreeFilter {
	return NewWorktreeFilter(&interfaces.RealFileSystem{})
}

// FilterActualWorktrees filters out main Git repositories, keeping only actual worktrees
func (wf *WorktreeFilter) FilterActualWorktrees(worktrees []*worktree.Worktree) []*worktree.Worktree {
	var actualWorktrees []*worktree.Worktree

	for _, wt := range worktrees {
		if wf.IsActualWorktree(wt) {
			actualWorktrees = append(actualWorktrees, wt)
		}
	}

	return actualWorktrees
}

// IsActualWorktree determines if a worktree is an actual worktree (not a main repository)
func (wf *WorktreeFilter) IsActualWorktree(wt *worktree.Worktree) bool {
	// Check if .git is a file (worktree) rather than a directory (main repo)
	gitPath := filepath.Join(wt.Path, ".git")
	if info, err := wf.fileSystem.Stat(gitPath); err == nil {
		return !info.IsDir() // If .git is a file, it's a worktree
	}

	// Additional heuristic: if the parent directory is named ".git" or contains "worktrees"
	// it's likely part of a worktree structure
	parentDir := filepath.Dir(wt.Path)
	if strings.Contains(parentDir, "worktrees") || filepath.Base(parentDir) == ".git" {
		return true
	}

	// If we can't determine, assume it's a main repo
	return false
}

// PromptValidator implements the PromptValidator interface
type PromptValidator struct{}

// NewPromptValidator creates a new prompt validator
func NewPromptValidator() *PromptValidator {
	return &PromptValidator{}
}

// ValidatePromptContent validates that prompt content is not empty and contains valid content
func (pv *PromptValidator) ValidatePromptContent(content string) error {
	content = strings.TrimSpace(content)
	if content == "" {
		return ErrEmptyPrompt
	}

	// Check for minimum length
	if len(content) < 10 {
		return ErrPromptTooShort
	}

	// Check that it's not just markdown structure
	cleanContent := strings.ReplaceAll(content, "#", "")
	cleanContent = strings.ReplaceAll(cleanContent, "-", "")
	cleanContent = strings.ReplaceAll(cleanContent, "*", "")
	cleanContent = strings.ReplaceAll(cleanContent, "`", "")
	cleanContent = strings.TrimSpace(cleanContent)

	if len(cleanContent) < 5 {
		return ErrPromptOnlyMarkdown
	}

	return nil
}

// ValidatePromptName validates that prompt name is valid
func (pv *PromptValidator) ValidatePromptName(name string) error {
	name = strings.TrimSpace(name)
	if name == "" {
		return ErrEmptyPromptName
	}

	// Check for valid characters (alphanumeric, dash, underscore)
	for _, r := range name {
		if !((r >= 'a' && r <= 'z') || (r >= 'A' && r <= 'Z') ||
			(r >= '0' && r <= '9') || r == '-' || r == '_' || r == ' ') {
			return ErrInvalidPromptName
		}
	}

	// Check length constraints
	if len(name) < 2 {
		return ErrPromptNameTooShort
	}
	if len(name) > 50 {
		return ErrPromptNameTooLong
	}

	return nil
}

// Custom errors for validation
var (
	ErrEmptyPrompt        = &ValidationError{Message: "prompt content cannot be empty"}
	ErrPromptTooShort     = &ValidationError{Message: "prompt content is too short (minimum 10 characters)"}
	ErrPromptOnlyMarkdown = &ValidationError{Message: "prompt contains only markdown formatting with no actual content"}
	ErrEmptyPromptName    = &ValidationError{Message: "prompt name cannot be empty"}
	ErrInvalidPromptName  = &ValidationError{Message: "prompt name contains invalid characters (use only letters, numbers, spaces, dashes, underscores)"}
	ErrPromptNameTooShort = &ValidationError{Message: "prompt name is too short (minimum 2 characters)"}
	ErrPromptNameTooLong  = &ValidationError{Message: "prompt name is too long (maximum 50 characters)"}
)

// ValidationError represents a validation error
type ValidationError struct {
	Message string
}

func (e *ValidationError) Error() string {
	return e.Message
}
