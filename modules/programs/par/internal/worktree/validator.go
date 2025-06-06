package worktree

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

// Validator handles worktree validation
type Validator struct{}

// NewValidator creates a new worktree validator
func NewValidator() *Validator {
	return &Validator{}
}

// ValidateWorktree validates a single worktree for par execution
func (v *Validator) ValidateWorktree(worktree *Worktree) {
	worktree.Errors = []string{}
	worktree.Valid = true
	
	// Check if path exists
	if !v.pathExists(worktree.Path) {
		v.addError(worktree, "path does not exist")
		return
	}
	
	// Check if it's a Git repository
	if !v.isGitRepository(worktree.Path) {
		v.addError(worktree, "not a Git repository")
	}
	
	// Check working directory status
	if err := v.checkWorkingDirectory(worktree); err != nil {
		v.addError(worktree, fmt.Sprintf("working directory issue: %v", err))
	}
	
	// Check for merge conflicts
	if v.hasMergeConflicts(worktree.Path) {
		v.addError(worktree, "has unresolved merge conflicts")
	}
	
	// Check if Claude Code CLI is accessible
	if !v.isClaudeCodeAvailable() {
		v.addError(worktree, "claude-code CLI not available")
	}
}

// FilterValid filters a list of worktrees to only include valid ones
func (v *Validator) FilterValid(worktrees []*Worktree) []*Worktree {
	var validWorktrees []*Worktree
	
	for _, worktree := range worktrees {
		v.ValidateWorktree(worktree)
		if worktree.Valid {
			validWorktrees = append(validWorktrees, worktree)
		}
	}
	
	return validWorktrees
}

// pathExists checks if a path exists
func (v *Validator) pathExists(path string) bool {
	_, err := os.Stat(path)
	return !os.IsNotExist(err)
}

// isGitRepository checks if a directory is a Git repository
func (v *Validator) isGitRepository(path string) bool {
	gitDir := filepath.Join(path, ".git")
	
	// Check for .git directory or file
	_, err := os.Stat(gitDir)
	return err == nil
}

// checkWorkingDirectory checks the Git working directory status
func (v *Validator) checkWorkingDirectory(worktree *Worktree) error {
	cmd := exec.Command("git", "status", "--porcelain")
	cmd.Dir = worktree.Path
	
	output, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("failed to check git status: %w", err)
	}
	
	// If there's output, there are uncommitted changes
	if len(strings.TrimSpace(string(output))) > 0 {
		return fmt.Errorf("has uncommitted changes")
	}
	
	return nil
}

// hasMergeConflicts checks for unresolved merge conflicts
func (v *Validator) hasMergeConflicts(path string) bool {
	// Check for merge head file
	mergeHeadFile := filepath.Join(path, ".git", "MERGE_HEAD")
	if _, err := os.Stat(mergeHeadFile); err == nil {
		return true
	}
	
	// Check for conflict markers in git status
	cmd := exec.Command("git", "status", "--porcelain")
	cmd.Dir = path
	
	output, err := cmd.Output()
	if err != nil {
		return false
	}
	
	lines := strings.Split(string(output), "\n")
	for _, line := range lines {
		if len(line) >= 2 && (line[0] == 'U' || line[1] == 'U' || 
			strings.HasPrefix(line, "AA") || strings.HasPrefix(line, "DD")) {
			return true
		}
	}
	
	return false
}

// isClaudeCodeAvailable checks if Claude Code CLI is available
func (v *Validator) isClaudeCodeAvailable() bool {
	cmd := exec.Command("claude-code", "--version")
	err := cmd.Run()
	return err == nil
}

// addError adds an error to the worktree and marks it as invalid
func (v *Validator) addError(worktree *Worktree, error string) {
	worktree.Errors = append(worktree.Errors, error)
	worktree.Valid = false
}