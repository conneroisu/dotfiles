package worktree

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/go-git/go-git/v5"
)

type Validator struct {
	strict bool
}

func NewValidator(strict bool) *Validator {
	return &Validator{
		strict: strict,
	}
}

func (v *Validator) ValidateWorktree(wt *Worktree) *ValidationResult {
	result := &ValidationResult{
		IsValid:  true,
		Errors:   []string{},
		Warnings: []string{},
	}
	
	// Check if path exists
	if !v.pathExists(wt.Path) {
		result.Errors = append(result.Errors, "worktree path does not exist")
		result.IsValid = false
		return result
	}
	
	// Check if it's a valid git repository
	if err := v.validateGitRepository(wt.Path); err != nil {
		result.Errors = append(result.Errors, fmt.Sprintf("invalid git repository: %v", err))
		result.IsValid = false
	}
	
	// Check working directory status
	if v.strict && wt.IsDirty {
		result.Errors = append(result.Errors, "working directory is dirty (has uncommitted changes)")
		result.IsValid = false
	} else if wt.IsDirty {
		result.Warnings = append(result.Warnings, "working directory has uncommitted changes")
	}
	
	// Check for unresolved merge conflicts
	if hasConflicts, err := v.checkMergeConflicts(wt.Path); err != nil {
		result.Warnings = append(result.Warnings, fmt.Sprintf("failed to check merge conflicts: %v", err))
	} else if hasConflicts {
		result.Errors = append(result.Errors, "worktree has unresolved merge conflicts")
		result.IsValid = false
	}
	
	// Check for common dependency files
	v.checkDependencies(wt.Path, result)
	
	// Check disk space
	if available, err := v.getAvailableSpace(wt.Path); err != nil {
		result.Warnings = append(result.Warnings, fmt.Sprintf("failed to check disk space: %v", err))
	} else if available < 100*1024*1024 { // Less than 100MB
		result.Warnings = append(result.Warnings, "low disk space available")
	}
	
	// Update the worktree's validity
	wt.IsValid = result.IsValid
	
	return result
}

func (v *Validator) ValidateWorktrees(worktrees []*Worktree) ([]*Worktree, map[string]*ValidationResult) {
	var valid []*Worktree
	results := make(map[string]*ValidationResult)
	
	for _, wt := range worktrees {
		result := v.ValidateWorktree(wt)
		results[wt.ID] = result
		
		if result.IsValid {
			valid = append(valid, wt)
		}
	}
	
	return valid, results
}

func (v *Validator) pathExists(path string) bool {
	_, err := os.Stat(path)
	return err == nil
}

func (v *Validator) validateGitRepository(path string) error {
	repo, err := git.PlainOpen(path)
	if err != nil {
		return fmt.Errorf("not a git repository: %w", err)
	}
	
	// Check if we can access the HEAD
	_, err = repo.Head()
	if err != nil {
		return fmt.Errorf("cannot access HEAD: %w", err)
	}
	
	return nil
}

func (v *Validator) checkMergeConflicts(path string) (bool, error) {
	repo, err := git.PlainOpen(path)
	if err != nil {
		return false, err
	}
	
	worktree, err := repo.Worktree()
	if err != nil {
		return false, err
	}
	
	status, err := worktree.Status()
	if err != nil {
		return false, err
	}
	
	// Check for files with merge conflicts
	// Note: go-git's status API has changed, this is a simplified check
	for _, fileStatus := range status {
		// Look for conflicted files by checking status codes
		// This is a basic implementation - real conflict detection would be more complex
		if string(fileStatus.Staging) == "?" || string(fileStatus.Worktree) == "?" {
			return true, nil
		}
	}
	
	return false, nil
}

func (v *Validator) checkDependencies(path string, result *ValidationResult) {
	dependencyFiles := map[string]string{
		"package.json":    "Node.js",
		"Cargo.toml":      "Rust",
		"go.mod":          "Go",
		"requirements.txt": "Python",
		"Gemfile":         "Ruby",
		"composer.json":   "PHP",
		"pom.xml":         "Java/Maven",
		"build.gradle":    "Java/Gradle",
	}
	
	var foundDeps []string
	for file, lang := range dependencyFiles {
		if v.pathExists(filepath.Join(path, file)) {
			foundDeps = append(foundDeps, lang)
		}
	}
	
	if len(foundDeps) > 0 {
		result.Warnings = append(result.Warnings, 
			fmt.Sprintf("project contains dependencies for: %v", foundDeps))
	}
	
	// Check for lock files that might need regeneration
	lockFiles := []string{
		"package-lock.json",
		"yarn.lock",
		"Cargo.lock",
		"go.sum",
		"Gemfile.lock",
		"composer.lock",
	}
	
	for _, lockFile := range lockFiles {
		if v.pathExists(filepath.Join(path, lockFile)) {
			result.Warnings = append(result.Warnings, 
				fmt.Sprintf("lock file %s present - dependencies may need installation", lockFile))
			break
		}
	}
}

func (v *Validator) getAvailableSpace(path string) (int64, error) {
	// This is a simplified implementation
	// In a real implementation, you'd use platform-specific calls
	stat, err := os.Stat(path)
	if err != nil {
		return 0, err
	}
	
	// This is a placeholder - actual implementation would use syscalls
	// For now, just return a reasonable default
	_ = stat
	return 1024 * 1024 * 1024, nil // 1GB placeholder
}

func (v *Validator) PrintValidationResults(results map[string]*ValidationResult, worktrees []*Worktree) {
	fmt.Println("Worktree Validation Results")
	fmt.Println("===========================")
	
	validCount := 0
	for _, wt := range worktrees {
		result := results[wt.ID]
		if result == nil {
			continue
		}
		
		status := "✓ VALID"
		if !result.IsValid {
			status = "✗ INVALID"
		} else {
			validCount++
		}
		
		fmt.Printf("%s %s (%s)\n", status, wt.GetDisplayName(), wt.Path)
		
		for _, error := range result.Errors {
			fmt.Printf("  ERROR: %s\n", error)
		}
		
		for _, warning := range result.Warnings {
			fmt.Printf("  WARNING: %s\n", warning)
		}
		
		if len(result.Errors) > 0 || len(result.Warnings) > 0 {
			fmt.Println()
		}
	}
	
	fmt.Printf("Summary: %d/%d worktrees are valid\n", validCount, len(worktrees))
}