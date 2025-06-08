package cmd

import (
	"fmt"
	"os"
	"strings"
	"text/tabwriter"
	"time"

	"github.com/spf13/cobra"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/prompts"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/worktree"
)

var (
	listJSON   bool
	listFilter string
)

var listCmd = &cobra.Command{
	Use:   "list [prompts|worktrees]",
	Short: "List available prompts and discovered worktrees",
	Long: `List available prompts and discovered worktrees. You can list all items,
or filter by type (prompts or worktrees).

Examples:
  par list                # List both prompts and worktrees
  par list prompts        # List only prompts
  par list worktrees      # List only worktrees
  par list --json         # Output in JSON format
  par list --filter="template"  # Filter items containing "template"`,
	Args: cobra.MaximumNArgs(1),
	RunE: runList,
}

func init() {
	listCmd.Flags().BoolVar(&listJSON, "json", false, "Output in JSON format")
	listCmd.Flags().StringVar(&listFilter, "filter", "", "Filter items by name or description")
}

func runList(cmd *cobra.Command, args []string) error {
	var listType string
	if len(args) > 0 {
		listType = args[0]
		if listType != "prompts" && listType != "worktrees" {
			return fmt.Errorf("invalid list type: %s (use 'prompts' or 'worktrees')", listType)
		}
	}

	if listType == "" || listType == "prompts" {
		if err := listPrompts(); err != nil {
			return fmt.Errorf("failed to list prompts: %w", err)
		}
	}

	if listType == "" || listType == "worktrees" {
		if listType == "" {
			fmt.Println() // Add separator when listing both
		}
		if err := listWorktrees(); err != nil {
			return fmt.Errorf("failed to list worktrees: %w", err)
		}
	}

	return nil
}

func listPrompts() error {
	manager, err := prompts.NewManager()
	if err != nil {
		return fmt.Errorf("failed to initialize prompts manager: %w", err)
	}

	promptList, err := manager.List()
	if err != nil {
		return fmt.Errorf("failed to get prompts: %w", err)
	}

	if listJSON {
		return printPromptsJSON(promptList)
	}

	return printPromptsTable(promptList)
}

func listWorktrees() error {
	discoverer := worktree.NewDiscoverer()
	worktrees, err := discoverer.FindWorktrees()
	if err != nil {
		return fmt.Errorf("failed to discover worktrees: %w", err)
	}

	if listJSON {
		return printWorktreesJSON(worktrees)
	}

	return printWorktreesTable(worktrees)
}

func printPromptsTable(promptList []*prompts.Prompt) error {
	if len(promptList) == 0 {
		fmt.Println("No prompts found.")
		return nil
	}

	fmt.Println("PROMPTS:")
	fmt.Println("========")

	w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
	fmt.Fprintln(w, "NAME\tTYPE\tDESCRIPTION\tTAGS\tCREATED")

	for _, prompt := range promptList {
		if listFilter != "" && !matchesFilter(prompt, listFilter) {
			continue
		}

		promptType := "prompt"
		if prompt.IsTemplate {
			promptType = "template"
		}

		tags := strings.Join(prompt.Tags, ",")
		if tags == "" {
			tags = "-"
		}

		created := prompt.CreatedAt.Format("2006-01-02")

		description := prompt.Description
		if len(description) > 50 {
			description = description[:47] + "..."
		}

		fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\n",
			prompt.Name, promptType, description, tags, created)
	}

	return w.Flush()
}

func printWorktreesTable(worktrees []*worktree.Worktree) error {
	if len(worktrees) == 0 {
		fmt.Println("No worktrees found.")
		return nil
	}

	fmt.Println("WORKTREES:")
	fmt.Println("==========")

	w := tabwriter.NewWriter(os.Stdout, 0, 0, 2, ' ', 0)
	fmt.Fprintln(w, "PROJECT\tBRANCH\tSTATUS\tPATH")

	for _, wt := range worktrees {
		if listFilter != "" && !matchesWorktreeFilter(wt, listFilter) {
			continue
		}

		status := "clean"
		if wt.IsDirty {
			status = "dirty"
		}
		if !wt.IsValid {
			status = "invalid"
		}

		projectName := wt.GetDisplayName()
		path := wt.Path

		// Shorten long paths
		if len(path) > 60 {
			path = "..." + path[len(path)-57:]
		}

		fmt.Fprintf(w, "%s\t%s\t%s\t%s\n",
			projectName, wt.Branch, status, path)
	}

	return w.Flush()
}

func printPromptsJSON(promptList []*prompts.Prompt) error {
	// For simplicity, print a basic JSON representation
	fmt.Println("[")
	for i, prompt := range promptList {
		if listFilter != "" && !matchesFilter(prompt, listFilter) {
			continue
		}

		if i > 0 {
			fmt.Println(",")
		}

		fmt.Printf(`  {
    "name": "%s",
    "description": "%s",
    "is_template": %t,
    "tags": [%s],
    "created_at": "%s"
  }`, prompt.Name, 
			escapeJSON(prompt.Description),
			prompt.IsTemplate,
			formatJSONTags(prompt.Tags),
			prompt.CreatedAt.Format(time.RFC3339))
	}
	fmt.Println("\n]")
	return nil
}

func printWorktreesJSON(worktrees []*worktree.Worktree) error {
	fmt.Println("[")
	for i, wt := range worktrees {
		if listFilter != "" && !matchesWorktreeFilter(wt, listFilter) {
			continue
		}

		if i > 0 {
			fmt.Println(",")
		}

		fmt.Printf(`  {
    "id": "%s",
    "name": "%s",
    "project_name": "%s",
    "path": "%s",
    "branch": "%s",
    "remote_url": "%s",
    "is_dirty": %t,
    "is_valid": %t
  }`, wt.ID, wt.Name, wt.ProjectName, wt.Path, wt.Branch, wt.RemoteURL, wt.IsDirty, wt.IsValid)
	}
	fmt.Println("\n]")
	return nil
}

func matchesFilter(prompt *prompts.Prompt, filter string) bool {
	filter = strings.ToLower(filter)
	return strings.Contains(strings.ToLower(prompt.Name), filter) ||
		strings.Contains(strings.ToLower(prompt.Description), filter) ||
		containsTag(prompt.Tags, filter)
}

func matchesWorktreeFilter(wt *worktree.Worktree, filter string) bool {
	filter = strings.ToLower(filter)
	return strings.Contains(strings.ToLower(wt.Name), filter) ||
		strings.Contains(strings.ToLower(wt.ProjectName), filter) ||
		strings.Contains(strings.ToLower(wt.Branch), filter) ||
		strings.Contains(strings.ToLower(wt.Path), filter)
}

func containsTag(tags []string, filter string) bool {
	for _, tag := range tags {
		if strings.Contains(strings.ToLower(tag), filter) {
			return true
		}
	}
	return false
}

func escapeJSON(s string) string {
	// Basic JSON escaping
	s = strings.ReplaceAll(s, "\"", "\\\"")
	s = strings.ReplaceAll(s, "\n", "\\n")
	s = strings.ReplaceAll(s, "\r", "\\r")
	s = strings.ReplaceAll(s, "\t", "\\t")
	return s
}

func formatJSONTags(tags []string) string {
	if len(tags) == 0 {
		return ""
	}

	var quotedTags []string
	for _, tag := range tags {
		quotedTags = append(quotedTags, fmt.Sprintf(`"%s"`, escapeJSON(tag)))
	}
	return strings.Join(quotedTags, ", ")
}