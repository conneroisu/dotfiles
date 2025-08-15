package catls

import (
	"context"
	"fmt"
	"path/filepath"
	"strings"
)

// MarkdownOutput handles Markdown output formatting.
type MarkdownOutput struct {
	firstFile bool
}

// NewMarkdownOutput creates a new Markdown output formatter.
func NewMarkdownOutput() *MarkdownOutput {
	return &MarkdownOutput{
		firstFile: true,
	}
}

// WriteHeader writes the opening Markdown structure (no-op for Markdown).
func (o *MarkdownOutput) WriteHeader(ctx context.Context) error {
	select {
	case <-ctx.Done():
		return ctx.Err()
	default:
	}

	// No header needed for Markdown
	return nil
}

// WriteFile writes a single processed file to Markdown output.
func (o *MarkdownOutput) WriteFile(ctx context.Context, file ProcessedFile, cfg *Config) error {
	select {
	case <-ctx.Done():
		return ctx.Err()
	default:
	}

	// Add spacing between files (except for the first file)
	if !o.firstFile {
		fmt.Println()
	}
	o.firstFile = false

	// Write file header
	fmt.Printf("## %s\n\n", file.Info.RelPath)

	// Handle errors
	if file.Error != nil {
		fmt.Printf("**Error:** %s\n\n", file.Error.Error())
		return nil
	}

	// Handle binary files
	if file.Info.IsBinary {
		fmt.Println("*Binary file - contents not displayed*\n")
		return nil
	}

	// Determine language for syntax highlighting
	language := o.getLanguageForSyntaxHighlighting(file.FileType, file.Info.RelPath)

	// Write code block with content
	fmt.Printf("```%s name=\"%s\"\n", language, filepath.Base(file.Info.RelPath))

	// Write content lines
	for _, line := range file.Lines {
		if cfg.ShowLineNumbers {
			fmt.Printf("%4d| %s\n", line.LineNumber, line.Content)
		} else {
			fmt.Println(line.Content)
		}
	}

	// Handle truncation
	if file.IsTruncated {
		remainingLines := file.TotalLines - len(file.Lines)
		if remainingLines > 0 {
			fmt.Printf("... (%d more lines)\n", remainingLines)
		}
	}

	fmt.Println("```")

	return nil
}

// WriteFooter writes the closing Markdown structure (no-op for Markdown).
func (o *MarkdownOutput) WriteFooter(ctx context.Context) error {
	select {
	case <-ctx.Done():
		return ctx.Err()
	default:
	}

	// No footer needed for Markdown
	return nil
}

// getLanguageForSyntaxHighlighting maps file types to syntax highlighting languages.
func (o *MarkdownOutput) getLanguageForSyntaxHighlighting(fileType, filePath string) string {
	// Use the detected file type first
	if fileType != "" {
		switch fileType {
		case "bash":
			return "bash"
		case "ruby":
			return "ruby"
		case "python":
			return "python"
		case "javascript":
			return "javascript"
		case "typescript":
			return "typescript"
		case "html":
			return "html"
		case "nix":
			return "nix"
		case "css":
			return "css"
		case "scss", "sass":
			return "scss"
		case "json":
			return "json"
		case "markdown":
			return "markdown"
		case "xml":
			return "xml"
		case "c":
			return "c"
		case "cpp":
			return "cpp"
		case "toml":
			return "toml"
		case "java":
			return "java"
		case "rust":
			return "rust"
		case "go":
			return "go"
		case "php":
			return "php"
		case "perl":
			return "perl"
		case "sql":
			return "sql"
		case "templ":
			return "go" // templ files are Go-like
		case "yaml":
			return "yaml"
		case "dockerfile":
			return "dockerfile"
		case "makefile":
			return "makefile"
		}
	}

	// Fallback to extension-based detection
	ext := strings.ToLower(strings.TrimPrefix(filepath.Ext(filePath), "."))
	switch ext {
	case "sh", "bash", "zsh":
		return "bash"
	case "rb":
		return "ruby"
	case "py":
		return "python"
	case "js", "jsx":
		return "javascript"
	case "ts", "tsx":
		return "typescript"
	case "html", "htm":
		return "html"
	case "nix":
		return "nix"
	case "css":
		return "css"
	case "scss", "sass":
		return "scss"
	case "json":
		return "json"
	case "md", "markdown":
		return "markdown"
	case "xml":
		return "xml"
	case "c", "h":
		return "c"
	case "cpp", "cxx", "cc", "hpp", "hxx":
		return "cpp"
	case "toml":
		return "toml"
	case "java":
		return "java"
	case "rs":
		return "rust"
	case "go":
		return "go"
	case "php":
		return "php"
	case "pl":
		return "perl"
	case "sql":
		return "sql"
	case "templ":
		return "go"
	case "yml", "yaml":
		return "yaml"
	case "dockerfile":
		return "dockerfile"
	case "makefile":
		return "makefile"
	case "txt", "":
		return "text"
	default:
		return "text"
	}
}