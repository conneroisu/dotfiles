package catls

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/connerosiu/dotfiles/modules/programs/catls/internal/scanner"
)

// FileProcessor handles file content processing.
type FileProcessor struct {
	typeDetector TypeDetector
}

// ProcessedFile represents a file after processing.
type ProcessedFile struct {
	Info        scanner.FileInfo
	FileType    string
	Lines       []FilteredLine
	TotalLines  int
	IsTruncated bool
	Error       error
}

// TypeDetector defines interface for detecting file types.
type TypeDetector interface {
	DetectType(filePath string) string
}

// NewFileProcessor creates a new file processor.
func NewFileProcessor() *FileProcessor {
	return &FileProcessor{
		typeDetector: &ExtensionTypeDetector{},
	}
}

// ProcessFile processes a single file and returns its content.
func (p *FileProcessor) ProcessFile(file scanner.FileInfo, filter *FileFilter) ProcessedFile {
	result := ProcessedFile{
		Info: file,
	}

	if file.IsBinary {
		return result
	}

	// Detect file type
	result.FileType = p.typeDetector.DetectType(file.Path)

	// Read file content
	lines, err := p.readFileLines(file.Path)
	if err != nil {
		result.Error = err
		return result
	}

	result.TotalLines = len(lines)

	// Apply content filtering
	filteredLines := filter.FilterContent(lines)

	// Check if we need to truncate for display
	const maxDisplayLines = 1000
	const truncateToLines = 100

	if len(filteredLines) > maxDisplayLines && filter.contentPattern == nil {
		result.Lines = filteredLines[:truncateToLines]
		result.IsTruncated = true
	} else {
		result.Lines = filteredLines
	}

	return result
}

// readFileLines reads all lines from a file.
func (p *FileProcessor) readFileLines(filePath string) ([]string, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer func() {
		if closeErr := file.Close(); closeErr != nil {
			// Log close error - in a real app you'd use a proper logger
			fmt.Fprintf(os.Stderr, "Warning: failed to close file %s: %v\n", filePath, closeErr)
		}
	}()

	var lines []string
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		lines = append(lines, scanner.Text())
	}

	if err := scanner.Err(); err != nil {
		return nil, err
	}

	return lines, nil
}

// ExtensionTypeDetector detects file types based on extensions.
type ExtensionTypeDetector struct{}

// DetectType implements TypeDetector.
func (d *ExtensionTypeDetector) DetectType(filePath string) string {
	ext := strings.ToLower(strings.TrimPrefix(filepath.Ext(filePath), "."))

	typeMap := map[string]string{
		"sh":         "bash",
		"bash":       "bash",
		"rb":         "ruby",
		"py":         "python",
		"js":         "javascript",
		"ts":         "typescript",
		"jsx":        "javascript",
		"tsx":        "typescript",
		"html":       "html",
		"htm":        "html",
		"nix":        "nix",
		"css":        "css",
		"scss":       "scss",
		"sass":       "sass",
		"json":       "json",
		"md":         "markdown",
		"markdown":   "markdown",
		"xml":        "xml",
		"c":          "c",
		"cpp":        "cpp",
		"cxx":        "cpp",
		"cc":         "cpp",
		"h":          "c",
		"hpp":        "cpp",
		"hxx":        "cpp",
		"toml":       "toml",
		"java":       "java",
		"rs":         "rust",
		"go":         "go",
		"php":        "php",
		"pl":         "perl",
		"sql":        "sql",
		"templ":      "templ",
		"yml":        "yaml",
		"yaml":       "yaml",
		"dockerfile": "dockerfile",
		"makefile":   "makefile",
	}

	if fileType, exists := typeMap[ext]; exists {
		return fileType
	}
	return ""
}
