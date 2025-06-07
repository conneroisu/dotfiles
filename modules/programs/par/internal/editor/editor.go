package editor

import (
	"fmt"
	"os"
	"strings"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/interfaces"
)

// Launcher implements the EditorLauncher interface
type Launcher struct {
	fileSystem interfaces.FileSystem
	commander  interfaces.CommandExecutor
	env        interfaces.Environment
	processor  interfaces.MarkdownProcessor
}

// NewLauncher creates a new editor launcher with the provided dependencies
func NewLauncher(fs interfaces.FileSystem, cmd interfaces.CommandExecutor, env interfaces.Environment, proc interfaces.MarkdownProcessor) *Launcher {
	return &Launcher{
		fileSystem: fs,
		commander:  cmd,
		env:        env,
		processor:  proc,
	}
}

// NewDefaultLauncher creates a launcher with real implementations
func NewDefaultLauncher() *Launcher {
	return NewLauncher(
		&interfaces.RealFileSystem{},
		&interfaces.RealCommandExecutor{},
		&interfaces.RealEnvironment{},
		NewMarkdownProcessor(),
	)
}

// LaunchEditor launches the user's editor with a markdown template
func (l *Launcher) LaunchEditor(promptName string, isTemplate bool) (string, error) {
	// Get editor from environment or default to vim
	editor := l.env.Getenv("EDITOR")
	if editor == "" {
		editor = "vim"
	}

	// Create temporary file with markdown extension
	tempDir := l.fileSystem.TempDir()
	fileName := "par-prompt-*.md"
	if promptName != "" {
		// Sanitize prompt name for filename
		safeName := strings.ReplaceAll(promptName, " ", "-")
		safeName = strings.ReplaceAll(safeName, "/", "-")
		fileName = fmt.Sprintf("par-prompt-%s-*.md", safeName)
	}

	tempFile, err := l.fileSystem.CreateTemp(tempDir, fileName)
	if err != nil {
		return "", fmt.Errorf("failed to create temporary file: %w", err)
	}
	defer l.fileSystem.Remove(tempFile.Name())
	defer tempFile.Close()

	// Write markdown template to the file
	template := l.processor.GenerateTemplate(promptName, isTemplate)
	if _, err := tempFile.WriteString(template); err != nil {
		return "", fmt.Errorf("failed to write template to file: %w", err)
	}

	// Close file so editor can write to it
	tempFile.Close()

	// Launch editor
	cmd := l.commander.Command(editor, tempFile.Name())
	cmd.SetStdin(os.Stdin)
	cmd.SetStdout(os.Stdout)
	cmd.SetStderr(os.Stderr)

	if err := cmd.Run(); err != nil {
		return "", fmt.Errorf("editor command failed: %w", err)
	}

	// Read the content back
	content, err := l.fileSystem.ReadFile(tempFile.Name())
	if err != nil {
		return "", fmt.Errorf("failed to read edited content: %w", err)
	}

	// Extract just the prompt content
	return l.processor.ExtractContent(string(content)), nil
}

// MarkdownProcessor implements the MarkdownProcessor interface
type MarkdownProcessor struct{}

// NewMarkdownProcessor creates a new markdown processor
func NewMarkdownProcessor() *MarkdownProcessor {
	return &MarkdownProcessor{}
}

// GenerateTemplate creates a markdown template for the prompt
func (mp *MarkdownProcessor) GenerateTemplate(promptName string, isTemplate bool) string {
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

// ExtractContent extracts the actual prompt content from the markdown
func (mp *MarkdownProcessor) ExtractContent(content string) string {
	lines := strings.Split(content, "\n")
	var promptLines []string
	inPromptSection := false

	for _, line := range lines {
		// Skip comment lines
		if strings.HasPrefix(strings.TrimSpace(line), "<!--") {
			continue
		}

		// Start collecting after "Your Prompt" section or after separator
		if strings.Contains(line, "## Your Prompt") {
			inPromptSection = true
			continue
		}
		if strings.TrimSpace(line) == "---" {
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
			if !strings.HasPrefix(trimmed, "<!--") && !strings.HasSuffix(trimmed, "-->") &&
				!strings.HasPrefix(trimmed, "#") && trimmed != "---" {
				cleanLines = append(cleanLines, line)
			}
		}
		result = strings.TrimSpace(strings.Join(cleanLines, "\n"))
	}

	return result
}
