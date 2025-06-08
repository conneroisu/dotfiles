package worktree

import (
	"os"
	"path/filepath"
	"strings"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/config"
)

// Validator handles worktree validation
type Validator struct {
	config *config.Config
}

// NewValidator creates a new validator
func NewValidator(cfg *config.Config) *Validator {
	return &Validator{
		config: cfg,
	}
}

// FilterValid filters out invalid worktrees
func (v *Validator) FilterValid(worktrees []*Worktree) []*Worktree {
	var valid []*Worktree

	for _, wt := range worktrees {
		if v.IsValid(wt) {
			valid = append(valid, wt)
		}
	}

	return valid
}

// IsValid checks if a worktree is valid for par execution
func (v *Validator) IsValid(wt *Worktree) bool {
	// Check if path exists
	if wt.Path == "" {
		return false
	}

	// Skip temporary worktrees in validation (they're managed separately)
	if wt.IsTemp {
		return true
	}

	// Check exclude patterns
	for _, pattern := range v.config.Worktrees.ExcludePatterns {
		if v.matchesExcludePattern(wt.Path, pattern) {
			return false
		}
	}

	// Check if it's a reasonable project (has some common project files)
	if !v.looksLikeProject(wt.Path) {
		return false
	}

	// Skip if it's a fork/mirror of a temporary worktree
	if v.isTemporaryWorktreePattern(wt.Path) {
		return false
	}

	return true
}

// matchesExcludePattern checks if path matches exclude pattern
func (v *Validator) matchesExcludePattern(path, pattern string) bool {
	// Handle wildcards in patterns
	if strings.Contains(pattern, "*") {
		// Simple wildcard matching
		parts := strings.Split(pattern, "*")
		for _, part := range parts {
			if part != "" && strings.Contains(path, part) {
				return true
			}
		}
		return false
	}

	// Exact or substring match
	return strings.Contains(path, pattern)
}

// looksLikeProject checks if directory contains project indicators
func (v *Validator) looksLikeProject(path string) bool {
	// Common project file indicators
	projectFiles := []string{
		"package.json",
		"Cargo.toml",
		"go.mod",
		"pom.xml",
		"build.gradle",
		"Makefile",
		"CMakeLists.txt",
		"requirements.txt",
		"setup.py",
		"composer.json",
		"flake.nix",
		"README.md",
		"README.rst",
		"README.txt",
	}

	for _, file := range projectFiles {
		filePath := filepath.Join(path, file)
		if _, err := os.Stat(filePath); err == nil {
			return true
		}
	}

	// Check for common source directories
	srcDirs := []string{
		"src",
		"lib",
		"app",
		"cmd",
		"internal",
		"pkg",
	}

	for _, dir := range srcDirs {
		dirPath := filepath.Join(path, dir)
		if stat, err := os.Stat(dirPath); err == nil && stat.IsDir() {
			return true
		}
	}

	return false
}

// isTemporaryWorktreePattern checks if path looks like a temporary worktree
func (v *Validator) isTemporaryWorktreePattern(path string) bool {
	// Check for feat/<feature>/try-<uuid> pattern
	return strings.Contains(path, "feat/") && strings.Contains(path, "try-")
}