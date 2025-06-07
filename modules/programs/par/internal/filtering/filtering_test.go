package filtering

import (
	"os"
	"testing"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/interfaces"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/worktree"
)

func TestWorktreeFilter_IsActualWorktree_GitFile(t *testing.T) {
	// Setup mock filesystem
	mockFS := interfaces.NewMockFileSystem()

	// Mock .git as a file (indicates worktree)
	mockFS.FileInfos["/path/to/worktree/.git"] = interfaces.NewTestableFileInfo(".git", 100, 0644, false)

	filter := NewWorktreeFilter(mockFS)

	wt := &worktree.Worktree{
		Path: "/path/to/worktree",
	}

	result := filter.IsActualWorktree(wt)

	if !result {
		t.Error("Expected worktree with .git file to be identified as actual worktree")
	}
}

func TestWorktreeFilter_IsActualWorktree_GitDirectory(t *testing.T) {
	// Setup mock filesystem
	mockFS := interfaces.NewMockFileSystem()

	// Mock .git as a directory (indicates main repo)
	mockFS.FileInfos["/path/to/repo/.git"] = interfaces.NewTestableFileInfo(".git", 0, 0755, true)

	filter := NewWorktreeFilter(mockFS)

	wt := &worktree.Worktree{
		Path: "/path/to/repo",
	}

	result := filter.IsActualWorktree(wt)

	if result {
		t.Error("Expected repository with .git directory to NOT be identified as actual worktree")
	}
}

func TestWorktreeFilter_IsActualWorktree_WorktreesPath(t *testing.T) {
	// Setup mock filesystem
	mockFS := interfaces.NewMockFileSystem()

	// Mock .git file not existing, but path contains "worktrees"
	mockFS.StatFn = func(name string) (os.FileInfo, error) {
		return nil, os.ErrNotExist
	}

	filter := NewWorktreeFilter(mockFS)

	wt := &worktree.Worktree{
		Path: "/repo/.git/worktrees/branch-name",
	}

	result := filter.IsActualWorktree(wt)

	if !result {
		t.Error("Expected path containing 'worktrees' to be identified as actual worktree")
	}
}

func TestWorktreeFilter_IsActualWorktree_GitParentDir(t *testing.T) {
	// Setup mock filesystem
	mockFS := interfaces.NewMockFileSystem()

	// Mock .git file not existing, but parent directory is ".git"
	mockFS.StatFn = func(name string) (os.FileInfo, error) {
		return nil, os.ErrNotExist
	}

	filter := NewWorktreeFilter(mockFS)

	wt := &worktree.Worktree{
		Path: "/repo/.git/branch-name",
	}

	result := filter.IsActualWorktree(wt)

	if !result {
		t.Error("Expected path with .git parent directory to be identified as actual worktree")
	}
}

func TestWorktreeFilter_IsActualWorktree_MainRepo(t *testing.T) {
	// Setup mock filesystem
	mockFS := interfaces.NewMockFileSystem()

	// Mock .git file not existing and no worktree indicators
	mockFS.StatFn = func(name string) (os.FileInfo, error) {
		return nil, os.ErrNotExist
	}

	filter := NewWorktreeFilter(mockFS)

	wt := &worktree.Worktree{
		Path: "/path/to/regular/repo",
	}

	result := filter.IsActualWorktree(wt)

	if result {
		t.Error("Expected regular repository path to NOT be identified as actual worktree")
	}
}

func TestWorktreeFilter_FilterActualWorktrees(t *testing.T) {
	// Setup mock filesystem
	mockFS := interfaces.NewMockFileSystem()

	// Setup different types of repositories
	mockFS.FileInfos["/worktree1/.git"] = interfaces.NewTestableFileInfo(".git", 100, 0644, false) // file = worktree
	mockFS.FileInfos["/mainrepo/.git"] = interfaces.NewTestableFileInfo(".git", 0, 0755, true)     // dir = main repo
	mockFS.StatFn = func(name string) (os.FileInfo, error) {
		if info, exists := mockFS.FileInfos[name]; exists {
			return info, nil
		}
		return nil, os.ErrNotExist
	}

	filter := NewWorktreeFilter(mockFS)

	worktrees := []*worktree.Worktree{
		{Name: "worktree1", Path: "/worktree1"},
		{Name: "mainrepo", Path: "/mainrepo"},
		{Name: "worktree-in-path", Path: "/repo/.git/worktrees/branch"},
	}

	filtered := filter.FilterActualWorktrees(worktrees)

	if len(filtered) != 2 {
		t.Errorf("Expected 2 actual worktrees, got %d", len(filtered))
	}

	// Verify correct worktrees were kept
	expectedNames := map[string]bool{"worktree1": true, "worktree-in-path": true}
	for _, wt := range filtered {
		if !expectedNames[wt.Name] {
			t.Errorf("Unexpected worktree in filtered results: %s", wt.Name)
		}
	}
}

func TestPromptValidator_ValidatePromptContent_Valid(t *testing.T) {
	validator := NewPromptValidator()

	validContent := "This is a valid prompt with sufficient content to pass validation."

	err := validator.ValidatePromptContent(validContent)

	if err != nil {
		t.Errorf("Expected no error for valid content, got: %v", err)
	}
}

func TestPromptValidator_ValidatePromptContent_Empty(t *testing.T) {
	validator := NewPromptValidator()

	err := validator.ValidatePromptContent("")

	if err != ErrEmptyPrompt {
		t.Errorf("Expected ErrEmptyPrompt, got: %v", err)
	}
}

func TestPromptValidator_ValidatePromptContent_Whitespace(t *testing.T) {
	validator := NewPromptValidator()

	err := validator.ValidatePromptContent("   \n\t   ")

	if err != ErrEmptyPrompt {
		t.Errorf("Expected ErrEmptyPrompt for whitespace-only content, got: %v", err)
	}
}

func TestPromptValidator_ValidatePromptContent_TooShort(t *testing.T) {
	validator := NewPromptValidator()

	err := validator.ValidatePromptContent("short")

	if err != ErrPromptTooShort {
		t.Errorf("Expected ErrPromptTooShort, got: %v", err)
	}
}

func TestPromptValidator_ValidatePromptContent_OnlyMarkdown(t *testing.T) {
	validator := NewPromptValidator()

	err := validator.ValidatePromptContent("### --- *** ```")

	if err != ErrPromptOnlyMarkdown {
		t.Errorf("Expected ErrPromptOnlyMarkdown, got: %v", err)
	}
}

func TestPromptValidator_ValidatePromptName_Valid(t *testing.T) {
	validator := NewPromptValidator()

	validNames := []string{
		"test-prompt",
		"test_prompt",
		"Test Prompt 123",
		"simple",
		"a-b",
	}

	for _, name := range validNames {
		err := validator.ValidatePromptName(name)
		if err != nil {
			t.Errorf("Expected no error for valid name '%s', got: %v", name, err)
		}
	}
}

func TestPromptValidator_ValidatePromptName_Empty(t *testing.T) {
	validator := NewPromptValidator()

	err := validator.ValidatePromptName("")

	if err != ErrEmptyPromptName {
		t.Errorf("Expected ErrEmptyPromptName, got: %v", err)
	}
}

func TestPromptValidator_ValidatePromptName_Whitespace(t *testing.T) {
	validator := NewPromptValidator()

	err := validator.ValidatePromptName("   ")

	if err != ErrEmptyPromptName {
		t.Errorf("Expected ErrEmptyPromptName for whitespace-only name, got: %v", err)
	}
}

func TestPromptValidator_ValidatePromptName_InvalidCharacters(t *testing.T) {
	validator := NewPromptValidator()

	invalidNames := []string{
		"test@prompt",
		"test#prompt",
		"test%prompt",
		"test!prompt",
		"test&prompt",
	}

	for _, name := range invalidNames {
		err := validator.ValidatePromptName(name)
		if err != ErrInvalidPromptName {
			t.Errorf("Expected ErrInvalidPromptName for '%s', got: %v", name, err)
		}
	}
}

func TestPromptValidator_ValidatePromptName_TooShort(t *testing.T) {
	validator := NewPromptValidator()

	err := validator.ValidatePromptName("a")

	if err != ErrPromptNameTooShort {
		t.Errorf("Expected ErrPromptNameTooShort, got: %v", err)
	}
}

func TestPromptValidator_ValidatePromptName_TooLong(t *testing.T) {
	validator := NewPromptValidator()

	longName := "this-is-a-very-long-prompt-name-that-exceeds-the-maximum-allowed-length-limit"
	err := validator.ValidatePromptName(longName)

	if err != ErrPromptNameTooLong {
		t.Errorf("Expected ErrPromptNameTooLong, got: %v", err)
	}
}

func TestValidationError_Error(t *testing.T) {
	err := &ValidationError{Message: "test error message"}

	if err.Error() != "test error message" {
		t.Errorf("Expected 'test error message', got: %s", err.Error())
	}
}
