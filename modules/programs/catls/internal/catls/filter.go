package catls

import (
	"fmt"
	"os"
	"regexp"

	"github.com/connerosiu/dotfiles/modules/programs/catls/internal/scanner"
)

// FileFilter handles file and content filtering.
type FileFilter struct {
	contentPattern *regexp.Regexp
}

// FilteredLine represents a line with its original line number.
type FilteredLine struct {
	LineNumber int
	Content    string
}

// NewFileFilter creates a new file filter.
func NewFileFilter(cfg *Config) *FileFilter {
	filter := &FileFilter{}
	
	// Compile content pattern if provided
	if cfg.ContentPattern != "" {
		regexPattern := scanner.WildcardToRegex(cfg.ContentPattern)
		if compiled, err := regexp.Compile(regexPattern); err == nil {
			filter.contentPattern = compiled
		}
	}
	
	return filter
}

// ShouldIncludeFile determines if a file should be included in output.
func (f *FileFilter) ShouldIncludeFile(file scanner.FileInfo, cfg *Config) bool {
	// Skip binary files if requested
	if cfg.OmitBins && file.IsBinary {
		if cfg.Debug {
			fmt.Fprintf(os.Stderr, "Debug: Skipping binary file: %s\n", file.RelPath)
		}
		return false
	}

	// Check ignore patterns first
	allIgnoreGlobs := cfg.AllIgnoreGlobs()
	for _, pattern := range allIgnoreGlobs {
		if scanner.MatchesGlobPattern(file.RelPath, pattern) {
			if cfg.Debug {
				fmt.Fprintf(os.Stderr, "Debug: Ignoring file: %s\n", file.RelPath)
			}
			return false
		}
	}

	// Check include patterns
	if len(cfg.Globs) == 0 {
		return true // Include everything if no specific patterns
	}

	for _, pattern := range cfg.Globs {
		if scanner.MatchesGlobPattern(file.RelPath, pattern) {
			return true
		}
	}

	return false
}

// FilterContent filters file content based on pattern.
func (f *FileFilter) FilterContent(lines []string) []FilteredLine {
	var result []FilteredLine

	if f.contentPattern == nil {
		// No pattern - return all lines
		for i, line := range lines {
			result = append(result, FilteredLine{
				LineNumber: i + 1,
				Content:    line,
			})
		}
		return result
	}

	// Filter lines matching pattern
	for i, line := range lines {
		if f.contentPattern.MatchString(line) {
			result = append(result, FilteredLine{
				LineNumber: i + 1,
				Content:    line,
			})
		}
	}

	return result
}