package cmd

import (
	"fmt"
	"os"
	"path/filepath"
	"text/tabwriter"
	"time"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/config"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/prompts"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/worktree"
	"github.com/spf13/cobra"
)

// listCmd represents the list command
var listCmd = &cobra.Command{
	Use:   "list [prompts|worktrees]",
	Short: "List available prompts and discovered worktrees",
	Long: `List available prompts and discovered worktrees.

Examples:
  par list          # List both prompts and worktrees
  par list prompts  # List only prompts
  par list worktrees # List only worktrees`,
	Args: cobra.MaximumNArgs(1),
	RunE: runList,
}

func init() {
	rootCmd.AddCommand(listCmd)
}

func runList(cmd *cobra.Command, args []string) error {
	listType := "all"
	if len(args) > 0 {
		listType = args[0]
	}

	switch listType {
	case "prompts":
		return listPrompts()
	case "worktrees":
		return listWorktrees()
	case "all":
		if err := listPrompts(); err != nil {
			return err
		}
		fmt.Println()
		return listWorktrees()
	default:
		return fmt.Errorf("invalid list type: %s (must be 'prompts', 'worktrees', or omitted for all)", listType)
	}
}

func listPrompts() error {
	manager, err := prompts.NewManager()
	if err != nil {
		return fmt.Errorf("failed to initialize prompt manager: %w", err)
	}

	promptList, err := manager.List()
	if err != nil {
		return fmt.Errorf("failed to list prompts: %w", err)
	}

	fmt.Printf("📝 Available Prompts (%d)\n", len(promptList))
	fmt.Println("=======================")

	if len(promptList) == 0 {
		fmt.Println("No prompts found. Use 'par add' to create a new prompt.")
		return nil
	}

	w := tabwriter.NewWriter(os.Stdout, 0, 8, 2, ' ', 0)
	fmt.Fprintln(w, "NAME\tTYPE\tDESCRIPTION\tMODIFIED")
	fmt.Fprintln(w, "----\t----\t-----------\t--------")

	for _, prompt := range promptList {
		promptType := "text"
		if prompt.IsTemplate {
			promptType = "template"
		}

		description := prompt.Description
		if description == "" {
			description = "(no description)"
		}
		if len(description) > 50 {
			description = description[:47] + "..."
		}

		modified := prompt.ModifiedAt.Format("2006-01-02 15:04")
		fmt.Fprintf(w, "%s\t%s\t%s\t%s\n", prompt.Name, promptType, description, modified)
	}

	w.Flush()
	return nil
}

func listWorktrees() error {
	cfg, err := config.Load()
	if err != nil {
		return fmt.Errorf("failed to load config: %w", err)
	}

	manager, err := worktree.NewManager(cfg)
	if err != nil {
		return fmt.Errorf("failed to initialize worktree manager: %w", err)
	}

	worktrees, err := manager.Discover()
	if err != nil {
		return fmt.Errorf("failed to discover worktrees: %w", err)
	}

	fmt.Printf("🌳 Discovered Worktrees (%d)\n", len(worktrees))
	fmt.Println("=========================")

	if len(worktrees) == 0 {
		fmt.Println("No valid worktrees found.")
		fmt.Println("\nSearch paths:")
		for _, path := range cfg.Worktrees.SearchPaths {
			fmt.Printf("  - %s\n", path)
		}
		return nil
	}

	w := tabwriter.NewWriter(os.Stdout, 0, 8, 2, ' ', 0)
	fmt.Fprintln(w, "NAME\tBRANCH\tSTATUS\tPATH")
	fmt.Fprintln(w, "----\t------\t------\t----")

	for _, wt := range worktrees {
		status := "✓ clean"
		if wt.IsDirty {
			status = "⚠️ dirty"
		}

		path := wt.Path
		if home, err := os.UserHomeDir(); err == nil {
			if rel, err := filepath.Rel(home, wt.Path); err == nil && !filepath.IsAbs(rel) {
				path = "~/" + rel
			}
		}

		fmt.Fprintf(w, "%s\t%s\t%s\t%s\n", wt.Name, wt.Branch, status, path)
	}

	w.Flush()
	return nil
}