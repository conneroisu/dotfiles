package cmd

import (
	"bytes"
	"strings"
	"testing"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/filtering"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/interfaces"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/worktree"
	"github.com/spf13/cobra"
)

// TestableListCommand wraps the list command with testable dependencies
type TestableListCommand struct {
	filter interfaces.WorktreeFilter
	cmd    *cobra.Command
	output *bytes.Buffer
}

// NewTestableListCommand creates a list command with injectable dependencies
func NewTestableListCommand(filter interfaces.WorktreeFilter) *TestableListCommand {
	tlc := &TestableListCommand{
		filter: filter,
		output: &bytes.Buffer{},
	}

	// Create a simplified version of the list command for testing worktree filtering
	tlc.cmd = &cobra.Command{
		Use:   "list worktrees",
		Short: "List discovered worktrees",
		RunE:  tlc.runListWorktrees,
	}

	tlc.cmd.Flags().BoolP("verbose", "v", false, "Show all Git repositories including main repos")

	return tlc
}

func (tlc *TestableListCommand) runListWorktrees(cmd *cobra.Command, args []string) error {
	verbose, _ := cmd.Flags().GetBool("verbose")

	// Mock worktree discovery - in real implementation this would come from discovery
	allWorktrees := []*worktree.Worktree{
		{Name: "main-repo", Path: "/repo1", Branch: "main", Valid: true},
		{Name: "actual-worktree", Path: "/repo1/.git/worktrees/feature", Branch: "feature", Valid: true},
		{Name: "another-repo", Path: "/repo2", Branch: "main", Valid: true},
		{Name: "worktree2", Path: "/repo2/.git/worktrees/dev", Branch: "dev", Valid: false, Errors: []string{"has uncommitted changes"}},
	}

	// Filter worktrees if not verbose
	filteredWorktrees := allWorktrees
	if !verbose {
		filteredWorktrees = tlc.filter.FilterActualWorktrees(allWorktrees)
	}

	// Generate output
	tlc.output.WriteString("Discovered worktrees:\n")
	tlc.output.WriteString("====================\n")

	validCount := 0
	for _, wt := range filteredWorktrees {
		tlc.output.WriteString("  " + wt.Name)
		if wt.Branch != "" {
			tlc.output.WriteString(" [" + wt.Branch + "]")
		}
		if !wt.Valid {
			tlc.output.WriteString(" (INVALID)")
		} else {
			validCount++
		}
		tlc.output.WriteString("\n")

		tlc.output.WriteString("    Path: " + wt.Path + "\n")

		if !wt.Valid && len(wt.Errors) > 0 {
			tlc.output.WriteString("    Errors: " + strings.Join(wt.Errors, ", ") + "\n")
		}

		tlc.output.WriteString("\n")
	}

	totalShown := len(filteredWorktrees)
	totalFound := len(allWorktrees)

	if verbose {
		tlc.output.WriteString("Total: " + string(rune(totalFound+'0')) + " worktrees (" + string(rune(validCount+'0')) + " valid, " + string(rune(totalShown-validCount+'0')) + " invalid)\n")
	} else {
		tlc.output.WriteString("Total: " + string(rune(totalShown+'0')) + " actual worktrees (" + string(rune(validCount+'0')) + " valid, " + string(rune(totalShown-validCount+'0')) + " invalid)\n")
		if totalFound > totalShown {
			tlc.output.WriteString("(Use -v/--verbose to show all " + string(rune(totalFound+'0')) + " Git repositories including main repos)\n")
		}
	}

	return nil
}

func (tlc *TestableListCommand) GetOutput() string {
	return tlc.output.String()
}

func TestListCommand_NonVerbose_FilteringApplied(t *testing.T) {
	// Setup mock filter that simulates filtering out main repos
	mockFilter := &interfaces.MockWorktreeFilter{
		FilterFunc: func(worktrees []*worktree.Worktree) []*worktree.Worktree {
			var actual []*worktree.Worktree
			for _, wt := range worktrees {
				// Filter out main repos (simulate the real filtering logic)
				if strings.Contains(wt.Path, "worktrees") {
					actual = append(actual, wt)
				}
			}
			return actual
		},
	}

	testCmd := NewTestableListCommand(mockFilter)
	testCmd.cmd.SetArgs([]string{})

	err := testCmd.cmd.Execute()

	if err != nil {
		t.Fatalf("Expected command to succeed, got error: %v", err)
	}

	output := testCmd.GetOutput()

	// Verify filtering was applied (should only show actual worktrees)
	if strings.Contains(output, "main-repo") {
		t.Error("Non-verbose mode should not show main repositories")
	}

	if !strings.Contains(output, "actual-worktree") {
		t.Error("Non-verbose mode should show actual worktrees")
	}

	if !strings.Contains(output, "worktree2") {
		t.Error("Non-verbose mode should show actual worktrees even if invalid")
	}

	// Verify summary indicates filtering
	if !strings.Contains(output, "actual worktrees") {
		t.Error("Non-verbose mode should indicate 'actual worktrees' in summary")
	}

	if !strings.Contains(output, "Use -v/--verbose") {
		t.Error("Non-verbose mode should show hint about verbose mode")
	}
}

func TestListCommand_Verbose_NoFilteringApplied(t *testing.T) {
	// Setup mock filter
	mockFilter := &interfaces.MockWorktreeFilter{
		FilterFunc: func(worktrees []*worktree.Worktree) []*worktree.Worktree {
			// This should not be called in verbose mode
			t.Error("Filter should not be called in verbose mode")
			return worktrees
		},
	}

	testCmd := NewTestableListCommand(mockFilter)
	testCmd.cmd.SetArgs([]string{"--verbose"})

	err := testCmd.cmd.Execute()

	if err != nil {
		t.Fatalf("Expected command to succeed, got error: %v", err)
	}

	output := testCmd.GetOutput()

	// Verify no filtering was applied (should show all repositories)
	if !strings.Contains(output, "main-repo") {
		t.Error("Verbose mode should show main repositories")
	}

	if !strings.Contains(output, "actual-worktree") {
		t.Error("Verbose mode should show actual worktrees")
	}

	if !strings.Contains(output, "another-repo") {
		t.Error("Verbose mode should show all repositories")
	}

	// Verify summary doesn't indicate filtering
	if strings.Contains(output, "actual worktrees") {
		t.Error("Verbose mode should not say 'actual worktrees' in summary")
	}

	if strings.Contains(output, "Use -v/--verbose") {
		t.Error("Verbose mode should not show verbose hint")
	}
}

func TestListCommand_ValidityStatus(t *testing.T) {
	// Setup mock filter that returns all worktrees
	mockFilter := &interfaces.MockWorktreeFilter{
		FilterFunc: func(worktrees []*worktree.Worktree) []*worktree.Worktree {
			return worktrees
		},
	}

	testCmd := NewTestableListCommand(mockFilter)
	testCmd.cmd.SetArgs([]string{})

	err := testCmd.cmd.Execute()

	if err != nil {
		t.Fatalf("Expected command to succeed, got error: %v", err)
	}

	output := testCmd.GetOutput()

	// Verify valid worktree doesn't show INVALID
	lines := strings.Split(output, "\n")
	var actualWorktreeLine string
	for _, line := range lines {
		if strings.Contains(line, "actual-worktree") {
			actualWorktreeLine = line
			break
		}
	}

	if strings.Contains(actualWorktreeLine, "(INVALID)") {
		t.Error("Valid worktree should not show (INVALID) status")
	}

	// Verify invalid worktree shows INVALID
	var worktree2Line string
	for _, line := range lines {
		if strings.Contains(line, "worktree2") {
			worktree2Line = line
			break
		}
	}

	if !strings.Contains(worktree2Line, "(INVALID)") {
		t.Error("Invalid worktree should show (INVALID) status")
	}

	// Verify error message is shown for invalid worktree
	if !strings.Contains(output, "has uncommitted changes") {
		t.Error("Invalid worktree should show error messages")
	}
}

func TestListCommand_BranchDisplay(t *testing.T) {
	mockFilter := &interfaces.MockWorktreeFilter{
		FilterFunc: func(worktrees []*worktree.Worktree) []*worktree.Worktree {
			return worktrees
		},
	}

	testCmd := NewTestableListCommand(mockFilter)
	testCmd.cmd.SetArgs([]string{})

	err := testCmd.cmd.Execute()

	if err != nil {
		t.Fatalf("Expected command to succeed, got error: %v", err)
	}

	output := testCmd.GetOutput()

	// Verify branch names are displayed in brackets
	if !strings.Contains(output, "[feature]") {
		t.Error("Should display branch name in brackets")
	}

	if !strings.Contains(output, "[dev]") {
		t.Error("Should display branch name in brackets")
	}
}

func TestListCommand_PathDisplay(t *testing.T) {
	mockFilter := &interfaces.MockWorktreeFilter{
		FilterFunc: func(worktrees []*worktree.Worktree) []*worktree.Worktree {
			return worktrees
		},
	}

	testCmd := NewTestableListCommand(mockFilter)
	testCmd.cmd.SetArgs([]string{})

	err := testCmd.cmd.Execute()

	if err != nil {
		t.Fatalf("Expected command to succeed, got error: %v", err)
	}

	output := testCmd.GetOutput()

	// Verify paths are displayed
	if !strings.Contains(output, "Path: /repo1/.git/worktrees/feature") {
		t.Error("Should display worktree paths")
	}

	if !strings.Contains(output, "Path: /repo2/.git/worktrees/dev") {
		t.Error("Should display worktree paths")
	}
}

// Integration test with real filtering component
func TestListCommand_Integration_RealFilter(t *testing.T) {
	// Setup real filtering component with mock filesystem
	mockFS := interfaces.NewMockFileSystem()

	// Setup filesystem to simulate different repository types
	mockFS.FileInfos["/repo1/.git"] = interfaces.NewTestableFileInfo(".git", 0, 0755, true)                           // main repo
	mockFS.FileInfos["/repo1/.git/worktrees/feature/.git"] = interfaces.NewTestableFileInfo(".git", 100, 0644, false) // worktree

	realFilter := filtering.NewWorktreeFilter(mockFS)

	testCmd := NewTestableListCommand(realFilter)
	testCmd.cmd.SetArgs([]string{}) // non-verbose

	err := testCmd.cmd.Execute()

	if err != nil {
		t.Fatalf("Expected integration test to succeed, got: %v", err)
	}

	output := testCmd.GetOutput()

	// Verify real filtering logic was applied
	// Should filter out main repos but keep actual worktrees
	if strings.Contains(output, "main-repo") || strings.Contains(output, "another-repo") {
		t.Error("Real filter should exclude main repositories in non-verbose mode")
	}

	if !strings.Contains(output, "actual-worktree") {
		t.Error("Real filter should include actual worktrees")
	}
}
