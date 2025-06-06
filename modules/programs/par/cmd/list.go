package cmd

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/config"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/prompts"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/worktree"
	"github.com/spf13/cobra"
)

var listCmd = &cobra.Command{
	Use:   "list [prompts|worktrees]",
	Short: "List available prompts and discovered worktrees",
	Long: `List available prompts in the prompt library and discovered Git worktrees
in the configured search paths. By default, only shows actual worktrees, not main repositories.`,
	ValidArgs: []string{"prompts", "worktrees"},
	Args:      cobra.MaximumNArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		listType := "all"
		if len(args) > 0 {
			listType = args[0]
		}

		verbose, _ := cmd.Flags().GetBool("verbose")

		// Load configuration
		cfg, err := config.Load()
		if err != nil {
			return fmt.Errorf("failed to load configuration: %w", err)
		}

		switch listType {
		case "prompts":
			return listPrompts(cfg)
		case "worktrees":
			return listWorktrees(cfg, verbose)
		default:
			if err := listPrompts(cfg); err != nil {
				return err
			}
			fmt.Println()
			return listWorktrees(cfg, verbose)
		}
	},
}

func listPrompts(cfg *config.Config) error {
	fmt.Println("Available prompts:")
	fmt.Println("==================")

	manager := prompts.NewManager(cfg.Prompts.StorageDir)
	promptList, err := manager.List()
	if err != nil {
		return fmt.Errorf("failed to list prompts: %w", err)
	}

	if len(promptList) == 0 {
		fmt.Println("No prompts found. Use 'par add' to create one.")
		return nil
	}

	for _, prompt := range promptList {
		fmt.Printf("  %s", prompt.Name)
		if prompt.Template {
			fmt.Printf(" (template, %d variables)", len(prompt.Variables))
		}
		fmt.Printf("\n")

		if prompt.Description != "" {
			fmt.Printf("    %s\n", prompt.Description)
		}

		if prompt.Template && len(prompt.Variables) > 0 {
			fmt.Printf("    Variables: ")
			for i, variable := range prompt.Variables {
				if i > 0 {
					fmt.Printf(", ")
				}
				fmt.Printf("%s", variable.Name)
				if variable.Required {
					fmt.Printf("*")
				}
			}
			fmt.Printf("\n")
		}

		fmt.Printf("    Created: %s\n", prompt.Created.Format("2006-01-02 15:04:05"))
		fmt.Println()
	}

	return nil
}

func listWorktrees(cfg *config.Config, verbose bool) error {
	fmt.Println("Discovered worktrees:")
	fmt.Println("====================")

	discovery := worktree.NewDiscovery(cfg.Worktrees.SearchPaths, cfg.Worktrees.ExcludePatterns)
	worktrees, err := discovery.FindWorktrees()
	if err != nil {
		return fmt.Errorf("failed to discover worktrees: %w", err)
	}

	if len(worktrees) == 0 {
		fmt.Println("No worktrees found in search paths:")
		for _, path := range cfg.Worktrees.SearchPaths {
			fmt.Printf("  - %s\n", path)
		}
		return nil
	}

	// Filter worktrees if not verbose
	filteredWorktrees := worktrees
	if !verbose {
		filteredWorktrees = filterActualWorktrees(worktrees)
	}

	// Validate worktrees
	validator := worktree.NewValidator(cfg)
	validCount := 0

	for _, wt := range filteredWorktrees {
		validator.ValidateWorktree(wt)

		fmt.Printf("  %s", wt.Name)
		if wt.Branch != "" {
			fmt.Printf(" [%s]", wt.Branch)
		}
		if !wt.Valid {
			fmt.Printf(" (INVALID)")
		} else {
			validCount++
		}
		fmt.Printf("\n")

		fmt.Printf("    Path: %s\n", wt.Path)

		if !wt.Valid && len(wt.Errors) > 0 {
			fmt.Printf("    Errors: %v\n", wt.Errors)
		}

		fmt.Println()
	}

	totalShown := len(filteredWorktrees)
	totalFound := len(worktrees)

	if verbose {
		fmt.Printf("Total: %d worktrees (%d valid, %d invalid)\n",
			totalFound, validCount, totalShown-validCount)
	} else {
		fmt.Printf("Total: %d actual worktrees (%d valid, %d invalid)\n",
			totalShown, validCount, totalShown-validCount)
		if totalFound > totalShown {
			fmt.Printf("(Use -v/--verbose to show all %d Git repositories including main repos)\n", totalFound)
		}
	}

	return nil
}

// filterActualWorktrees filters out main Git repositories, keeping only actual worktrees
func filterActualWorktrees(worktrees []*worktree.Worktree) []*worktree.Worktree {
	var actualWorktrees []*worktree.Worktree

	for _, wt := range worktrees {
		if isActualWorktree(wt) {
			actualWorktrees = append(actualWorktrees, wt)
		}
	}

	return actualWorktrees
}

// isActualWorktree determines if a worktree is an actual worktree (not a main repository)
func isActualWorktree(wt *worktree.Worktree) bool {
	// Check if .git is a file (worktree) rather than a directory (main repo)
	gitPath := filepath.Join(wt.Path, ".git")
	if info, err := os.Stat(gitPath); err == nil {
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

func init() {
	listCmd.Flags().BoolP("verbose", "v", false, "Show all Git repositories including main repos")
}
