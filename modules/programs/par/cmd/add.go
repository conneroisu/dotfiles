package cmd

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"strings"
	"time"

	"github.com/spf13/cobra"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/config"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/prompts"
)

var addCmd = &cobra.Command{
	Use:   "add [--name <name>] [--file <file>] [--template]",
	Short: "Add a new prompt to the library",
	Long: `Add a new prompt to the prompt library. Prompts can be added from stdin,
from a file, or interactively. Support for prompt templates with variables.`,
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
			// Read from stdin or interactive input
			fmt.Println("Enter prompt content (Ctrl+D or Ctrl+Z to finish):")
			data, err := io.ReadAll(os.Stdin)
			if err != nil {
				return fmt.Errorf("failed to read input: %w", err)
			}
			content = string(data)
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

func init() {
	addCmd.Flags().StringP("name", "n", "", "Name for the prompt")
	addCmd.Flags().StringP("file", "f", "", "File containing the prompt")
	addCmd.Flags().Bool("template", false, "Create a template prompt with variables")
}