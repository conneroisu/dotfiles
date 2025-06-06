package cmd

import (
	"bufio"
	"fmt"
	"log/slog"
	"os"
	"os/exec"
	"strings"
	"time"

	"github.com/spf13/cobra"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/config"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/prompts"
)

var addCmd = &cobra.Command{
	Use:   "add [--name <name>] [--file <file>] [--template]",
	Short: "Add a new prompt to the library",
	Long: `Add a new prompt to the prompt library. When no file is specified, 
launches your $EDITOR with a markdown template for writing prompts with 
syntax highlighting and structure. Supports template prompts with variables.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		name, err := cmd.Flags().GetString("name")
		if err != nil {
			return fmt.Errorf("failed to parse 'name' flag: %w", err)
		}
		file, err := cmd.Flags().GetString("file")
		if err != nil {
			return fmt.Errorf("failed to parse 'file' flag: %w", err)
		}
		template, err := cmd.Flags().GetBool("template")
		if err != nil {
			return fmt.Errorf("failed to parse 'template' flag: %w", err)
		}

		// Load configuration
		cfg, err := config.Load()
		if err != nil {
			return fmt.Errorf("failed to load configuration: %w", err)
		}
		
		// Ensure directories exist
		if err := cfg.EnsureDirectories(); err != nil {
			return fmt.Errorf("failed to create directories: %w", err)
		}
		
		// Create prompt manager
		manager := prompts.NewManager(cfg.Prompts.StorageDir)
		
		// Get prompt content
		var content string
		if file != "" {
			// Read from file
			data, err := os.ReadFile(file)
			if err != nil {
				return fmt.Errorf("failed to read file: %w", err)
			}
			content = string(data)
		} else {
			// Launch editor with markdown template
			content, err = launchEditorForPrompt(name, template)
			if err != nil {
				return fmt.Errorf("failed to get prompt content from editor: %w", err)
			}
		}
		
		content = strings.TrimSpace(content)
		if content == "" {
			return fmt.Errorf("prompt content cannot be empty")
		}
		
		// Get prompt name if not provided
		if name == "" {
			fmt.Print("Enter prompt name: ")
			reader := bufio.NewReader(os.Stdin)
			name, err = reader.ReadString('\n')
			if err != nil {
				return fmt.Errorf("failed to read prompt name: %w", err)
			}
			name = strings.TrimSpace(name)
		}
		
		if name == "" {
			return fmt.Errorf("prompt name cannot be empty")
		}
		
		// Check if prompt already exists
		if manager.Exists(name) {
			return fmt.Errorf("prompt '%s' already exists", name)
		}
		
		// Create prompt
		prompt := &prompts.Prompt{
			Name:        name,
			Description: fmt.Sprintf("Added on %s", time.Now().Format("2006-01-02 15:04:05")),
			Created:     time.Now(),
			Template:    template,
			Content:     content,
		}
		
		// Add template variables if it's a template
		if template {
			fmt.Println("Template mode: Add variable definitions (empty line to finish)")
			scanner := bufio.NewScanner(os.Stdin)
			
			for {
				fmt.Print("Variable name (or empty to finish): ")
				if !scanner.Scan() {
					if err := scanner.Err(); err != nil {
						return fmt.Errorf("error reading variable name: %w", err)
					}
					break
				}
				varName := strings.TrimSpace(scanner.Text())
				if varName == "" {
					break
				}
				
				fmt.Print("Description: ")
				if !scanner.Scan() {
					if err := scanner.Err(); err != nil {
						return fmt.Errorf("error reading description: %w", err)
					}
					break
				}
				description := strings.TrimSpace(scanner.Text())
				
				fmt.Print("Default value (optional): ")
				if !scanner.Scan() {
					if err := scanner.Err(); err != nil {
						return fmt.Errorf("error reading default value: %w", err)
					}
					break
				}
				defaultValue := strings.TrimSpace(scanner.Text())
				
				fmt.Print("Required? (y/N): ")
				if !scanner.Scan() {
					if err := scanner.Err(); err != nil {
						return fmt.Errorf("error reading required flag: %w", err)
					}
					break
				}
				required := strings.ToLower(strings.TrimSpace(scanner.Text())) == "y"
				
				variable := prompts.Variable{
					Name:        varName,
					Description: description,
					Default:     defaultValue,
					Required:    required,
				}
				
				prompt.Variables = append(prompt.Variables, variable)
			}
		}
		
		// Save prompt
		if err := manager.Save(prompt); err != nil {
			return fmt.Errorf("failed to save prompt: %w", err)
		}
		
		fmt.Printf("Prompt '%s' added successfully\n", name)
		if template {
			fmt.Printf("Template with %d variables\n", len(prompt.Variables))
		}
		
		return nil
	},
}

// launchEditorForPrompt creates a temporary markdown file and launches the user's editor
func launchEditorForPrompt(promptName string, isTemplate bool) (string, error) {
	// Get editor from environment or default to vim
	editor := os.Getenv("EDITOR")
	if editor == "" {
		editor = "vim"
	}

	// Create temporary file with markdown extension
	tempDir := os.TempDir()
	fileName := "par-prompt-*.md"
	if promptName != "" {
		// Sanitize prompt name for filename
		safeName := strings.ReplaceAll(promptName, " ", "-")
		safeName = strings.ReplaceAll(safeName, "/", "-")
		fileName = fmt.Sprintf("par-prompt-%s-*.md", safeName)
	}
	
	tempFile, err := os.CreateTemp(tempDir, fileName)
	if err != nil {
		return "", fmt.Errorf("failed to create temporary file: %w", err)
	}
	defer func() {
		if err := os.Remove(tempFile.Name()); err != nil {
			slog.Debug("Failed to remove temporary file", "path", tempFile.Name(), "error", err)
		}
	}()
	defer func() {
		if err := tempFile.Close(); err != nil {
			slog.Debug("Failed to close temporary file", "error", err)
		}
	}()

	// Write markdown template to the file
	template := generatePromptTemplate(promptName, isTemplate)
	if _, err := tempFile.WriteString(template); err != nil {
		return "", fmt.Errorf("failed to write template to file: %w", err)
	}

	// Close file so editor can write to it
	if err := tempFile.Close(); err != nil {
		return "", fmt.Errorf("failed to close temporary file: %w", err)
	}

	// Launch editor
	cmd := exec.Command(editor, tempFile.Name())
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("editor command failed: %w", err)
	}

	// Read the content back
	content, err := os.ReadFile(tempFile.Name())
	if err != nil {
		return "", fmt.Errorf("failed to read edited content: %w", err)
	}

	// Extract just the prompt content (everything after the frontmatter if present)
	return extractPromptContent(string(content)), nil
}

// generatePromptTemplate creates a markdown template for the prompt
func generatePromptTemplate(promptName string, isTemplate bool) string {
	var sb strings.Builder
	
	// Add frontmatter-style header
	sb.WriteString("<!-- Par Prompt Creation -->\n")
	sb.WriteString("<!-- Delete this comment section before saving -->\n")
	sb.WriteString("<!-- Write your prompt below this line -->\n")
	
	if promptName != "" {
		sb.WriteString(fmt.Sprintf("<!-- Prompt Name: %s -->\n", promptName))
	}
	
	if isTemplate {
		sb.WriteString("<!-- Template Mode: Variables can be used with Go template syntax like {{.VariableName}} -->\n")
		sb.WriteString("<!-- Example: Fix the {{.FunctionName}} function to {{.Requirement}} -->\n")
	}
	
	sb.WriteString("<!-- Available in editor: syntax highlighting, markdown preview, etc. -->\n")
	sb.WriteString("\n")
	sb.WriteString("---\n")
	sb.WriteString("\n")
	
	// Add prompt content area
	sb.WriteString("# Prompt Content\n")
	sb.WriteString("\n")
	
	if isTemplate {
		sb.WriteString("Write your template prompt here using Go template syntax for variables.\n")
		sb.WriteString("\n")
		sb.WriteString("Example:\n")
		sb.WriteString("```\n")
		sb.WriteString("Please refactor the {{.FunctionName}} function to improve {{.Aspect}}.\n")
		sb.WriteString("The function should {{.Requirements}}.\n")
		sb.WriteString("```\n")
	} else {
		sb.WriteString("Write your prompt here. This will be sent to Claude Code CLI for each worktree.\n")
		sb.WriteString("\n")
		sb.WriteString("Example:\n")
		sb.WriteString("```\n")
		sb.WriteString("Please review this codebase and suggest improvements for:\n")
		sb.WriteString("1. Code organization\n")
		sb.WriteString("2. Performance optimizations\n")
		sb.WriteString("3. Best practices\n")
		sb.WriteString("```\n")
	}
	
	sb.WriteString("\n")
	sb.WriteString("## Your Prompt\n")
	sb.WriteString("\n")
	sb.WriteString("<!-- Write your actual prompt content below -->\n")
	sb.WriteString("\n")
	
	return sb.String()
}

// extractPromptContent extracts the actual prompt content from the markdown
func extractPromptContent(content string) string {
	lines := strings.Split(content, "\n")
	var promptLines []string
	inPromptSection := false
	
	for _, line := range lines {
		// Skip comment lines
		if strings.HasPrefix(strings.TrimSpace(line), "<!--") {
			continue
		}
		
		// Start collecting after "Your Prompt" section or after separator
		if strings.Contains(line, "## Your Prompt") || strings.TrimSpace(line) == "---" {
			inPromptSection = true
			continue
		}
		
		if inPromptSection {
			// Skip empty comment lines
			trimmed := strings.TrimSpace(line)
			if trimmed == "" || strings.HasPrefix(trimmed, "<!--") {
				if trimmed != "" {
					continue
				}
			}
			promptLines = append(promptLines, line)
		}
	}
	
	// Clean up the result
	result := strings.Join(promptLines, "\n")
	result = strings.TrimSpace(result)
	
	// If no content found in the structured section, return the whole content minus comments
	if result == "" {
		var cleanLines []string
		for _, line := range lines {
			trimmed := strings.TrimSpace(line)
			if !strings.HasPrefix(trimmed, "<!--") && !strings.HasSuffix(trimmed, "-->") {
				cleanLines = append(cleanLines, line)
			}
		}
		result = strings.TrimSpace(strings.Join(cleanLines, "\n"))
	}
	
	return result
}

func init() {
	addCmd.Flags().StringP("name", "n", "", "Name for the prompt")
	addCmd.Flags().StringP("file", "f", "", "File containing the prompt")
	addCmd.Flags().Bool("template", false, "Create a template prompt with variables")
}