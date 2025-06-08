package cmd

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/prompts"
	"github.com/spf13/cobra"
)

var (
	addName        string
	addFile        string
	addTemplate    bool
	addDescription string
)

// addCmd represents the add command
var addCmd = &cobra.Command{
	Use:   "add [--name <name>] [--file <file>] [--template]",
	Short: "Add a new prompt to the library",
	Long: `Add a new prompt to the library for use with par run.

You can either:
- Provide prompt content interactively
- Read prompt from a file with --file
- Create a template prompt with --template`,
	RunE: runAdd,
}

func init() {
	rootCmd.AddCommand(addCmd)

	addCmd.Flags().StringVarP(&addName, "name", "n", "", "name for the prompt")
	addCmd.Flags().StringVarP(&addFile, "file", "f", "", "read prompt from file")
	addCmd.Flags().BoolVar(&addTemplate, "template", false, "create a template prompt")
	addCmd.Flags().StringVarP(&addDescription, "description", "d", "", "description for the prompt")
}

func runAdd(cmd *cobra.Command, args []string) error {
	manager, err := prompts.NewManager()
	if err != nil {
		return fmt.Errorf("failed to initialize prompt manager: %w", err)
	}

	var promptName string
	var promptContent string

	// Get prompt name
	if addName != "" {
		promptName = addName
	} else {
		fmt.Print("Enter prompt name: ")
		fmt.Scanln(&promptName)
	}

	if promptName == "" {
		return fmt.Errorf("prompt name is required")
	}

	// Validate prompt name
	if strings.ContainsAny(promptName, "/\\<>:\"|?*") {
		return fmt.Errorf("prompt name contains invalid characters")
	}

	// Get prompt content
	if addFile != "" {
		// Read from file
		content, err := os.ReadFile(addFile)
		if err != nil {
			return fmt.Errorf("failed to read file %s: %w", addFile, err)
		}
		promptContent = string(content)
	} else if addTemplate {
		// Create template prompt
		promptContent = `# {{.ProjectName}} - {{.TaskName}}

## Task Description
{{.Description}}

## Context
Project: {{.ProjectName}}
Branch: {{.BranchName}}
Worktree: {{.WorktreePath}}

## Instructions
{{.Instructions}}

## Expected Outcome
{{.ExpectedOutcome}}`
	} else {
		// Interactive input
		fmt.Println("Enter prompt content (end with Ctrl+D on empty line):")
		var lines []string
		for {
			var line string
			_, err := fmt.Scanln(&line)
			if err != nil {
				break
			}
			lines = append(lines, line)
		}
		promptContent = strings.Join(lines, "\n")
	}

	if promptContent == "" {
		return fmt.Errorf("prompt content is required")
	}

	// Create prompt
	prompt := &prompts.Prompt{
		Name:        promptName,
		Description: addDescription,
		Content:     promptContent,
		IsTemplate:  addTemplate,
	}

	err = manager.Save(prompt)
	if err != nil {
		return fmt.Errorf("failed to save prompt: %w", err)
	}

	promptPath := filepath.Join(manager.GetStorageDir(), promptName+".yaml")
	fmt.Printf("✓ Prompt '%s' saved to %s\n", promptName, promptPath)

	if addTemplate {
		fmt.Println("\n📝 Template variables available:")
		fmt.Println("  - {{.ProjectName}}    # Name of the project")
		fmt.Println("  - {{.TaskName}}       # Name of the task")
		fmt.Println("  - {{.Description}}    # Task description")
		fmt.Println("  - {{.BranchName}}     # Git branch name")
		fmt.Println("  - {{.WorktreePath}}   # Path to worktree")
		fmt.Println("  - {{.Instructions}}   # Specific instructions")
		fmt.Println("  - {{.ExpectedOutcome}} # Expected outcome")
	}

	return nil
}