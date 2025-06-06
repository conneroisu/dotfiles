package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/config"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/prompts"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/worktree"
)

var listCmd = &cobra.Command{
	Use:   "list [prompts|worktrees]",
	Short: "List available prompts and discovered worktrees",
	Long: `List available prompts in the prompt library and discovered Git worktrees
in the configured search paths.`,
	ValidArgs: []string{"prompts", "worktrees"},
	Args:      cobra.MaximumNArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		listType := "all"
		if len(args) > 0 {
			listType = args[0]
		}

		// Load configuration
		cfg, err := config.Load()
		if err != nil {
			return fmt.Errorf("failed to load configuration: %w", err)
		}

		switch listType {
		case "prompts":
			return listPrompts(cfg)
		case "worktrees":
			return listWorktrees(cfg)
		default:
			if err := listPrompts(cfg); err != nil {
				return err
			}
			fmt.Println()
			return listWorktrees(cfg)
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

func listWorktrees(cfg *config.Config) error {
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
	
	// Validate worktrees
	validator := worktree.NewValidator()
	validCount := 0
	
	for _, wt := range worktrees {
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
	
	fmt.Printf("Total: %d worktrees (%d valid, %d invalid)\n", 
		len(worktrees), validCount, len(worktrees)-validCount)
	
	return nil
}