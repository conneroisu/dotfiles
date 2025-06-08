package cmd

import (
	"bufio"
	"fmt"
	"os"
	"strings"

	"github.com/spf13/cobra"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/prompts"
)

var (
	addName        string
	addDescription string
	addFile        string
	addTemplate    bool
	addTags        []string
)

var addCmd = &cobra.Command{
	Use:   "add",
	Short: "Add a new prompt to the library",
	Long: `Add a new prompt to the library. You can add prompts interactively,
from a file, or create a template prompt.

Examples:
  par add --name "refactor-errors" --description "Refactor error handling patterns"
  par add --name "optimize-performance" --file ./prompts/optimize.txt
  par add --name "add-feature" --template --description "Add new feature template"`,
	RunE: runAdd,
}

func init() {
	addCmd.Flags().StringVarP(&addName, "name", "n", "", "Name for the prompt (required)")
	addCmd.Flags().StringVarP(&addDescription, "description", "d", "", "Description of the prompt")
	addCmd.Flags().StringVarP(&addFile, "file", "f", "", "File containing the prompt content")
	addCmd.Flags().BoolVarP(&addTemplate, "template", "t", false, "Create a template prompt")
	addCmd.Flags().StringSliceVar(&addTags, "tags", []string{}, "Tags for the prompt (comma-separated)")
}

func runAdd(cmd *cobra.Command, args []string) error {
	manager, err := prompts.NewManager()
	if err != nil {
		return fmt.Errorf("failed to initialize prompts manager: %w", err)
	}

	// Interactive mode if no name provided
	if addName == "" {
		return runInteractiveAdd(manager)
	}

	// Validate the name
	if err := manager.ValidateName(addName); err != nil {
		return fmt.Errorf("invalid prompt name: %w", err)
	}

	// Check if prompt already exists
	if manager.Exists(addName) {
		return fmt.Errorf("prompt '%s' already exists", addName)
	}

	var prompt *prompts.Prompt

	// Create template prompt
	if addTemplate {
		prompt = prompts.CreateTemplatePrompt(addName, addDescription)
		if len(addTags) > 0 {
			prompt.Tags = addTags
		}
	} else {
		// Create regular prompt
		prompt = prompts.CreateDefaultPrompt(addName, addDescription)
		if len(addTags) > 0 {
			prompt.Tags = addTags
		}

		// Load content from file or interactive input
		if addFile != "" {
			content, err := os.ReadFile(addFile)
			if err != nil {
				return fmt.Errorf("failed to read file '%s': %w", addFile, err)
			}
			prompt.Content = string(content)
		} else {
			content, err := getPromptContentInteractive()
			if err != nil {
				return fmt.Errorf("failed to get prompt content: %w", err)
			}
			prompt.Content = content
		}
	}

	// Save the prompt
	if err := manager.Save(prompt); err != nil {
		return fmt.Errorf("failed to save prompt: %w", err)
	}

	fmt.Printf("Successfully added prompt '%s'\n", addName)
	if addTemplate {
		fmt.Printf("Template prompt created. You can edit the variables and content as needed.\n")
	}
	fmt.Printf("Storage location: %s\n", manager.GetStorageDir())

	return nil
}

func runInteractiveAdd(manager *prompts.Manager) error {
	scanner := bufio.NewScanner(os.Stdin)

	fmt.Print("Enter prompt name: ")
	scanner.Scan()
	name := strings.TrimSpace(scanner.Text())

	if err := manager.ValidateName(name); err != nil {
		return fmt.Errorf("invalid prompt name: %w", err)
	}

	if manager.Exists(name) {
		return fmt.Errorf("prompt '%s' already exists", name)
	}

	fmt.Print("Enter description: ")
	scanner.Scan()
	description := strings.TrimSpace(scanner.Text())

	fmt.Print("Create as template? (y/N): ")
	scanner.Scan()
	isTemplate := strings.ToLower(strings.TrimSpace(scanner.Text())) == "y"

	fmt.Print("Enter tags (comma-separated, optional): ")
	scanner.Scan()
	tagsInput := strings.TrimSpace(scanner.Text())
	var tags []string
	if tagsInput != "" {
		for _, tag := range strings.Split(tagsInput, ",") {
			tags = append(tags, strings.TrimSpace(tag))
		}
	}

	var prompt *prompts.Prompt

	if isTemplate {
		prompt = prompts.CreateTemplatePrompt(name, description)
		prompt.Tags = tags
	} else {
		prompt = prompts.CreateDefaultPrompt(name, description)
		prompt.Tags = tags

		fmt.Println("\nEnter prompt content (end with Ctrl+D on Unix or Ctrl+Z on Windows):")
		content, err := getPromptContentInteractive()
		if err != nil {
			return fmt.Errorf("failed to get prompt content: %w", err)
		}
		prompt.Content = content
	}

	if err := manager.Save(prompt); err != nil {
		return fmt.Errorf("failed to save prompt: %w", err)
	}

	fmt.Printf("\nSuccessfully added prompt '%s'\n", name)
	if isTemplate {
		fmt.Printf("Template prompt created. You can edit the variables and content as needed.\n")
	}

	return nil
}

func getPromptContentInteractive() (string, error) {
	var lines []string
	scanner := bufio.NewScanner(os.Stdin)

	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}

	if err := scanner.Err(); err != nil {
		return "", fmt.Errorf("error reading input: %w", err)
	}

	return strings.Join(lines, "\n"), nil
}