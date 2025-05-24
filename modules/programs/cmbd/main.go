// Package main provides a command line tool for combining markdown files.
package main

import (
	"flag"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

// MarkdownCombiner handles the combination of markdown files.
type MarkdownCombiner struct {
	inputDir   string
	outputFile string
}

// removeYAMLFrontmatter removes YAML front matter from markdown content.
func removeYAMLFrontmatter(content string) string {
	lines := strings.Split(content, "\n")

	// Check if first line is "---" (YAML front matter start)
	if len(lines) < 3 || strings.TrimSpace(lines[0]) != "---" {
		return content
	}

	// Find the closing "---"
	for i := 1; i < len(lines); i++ {
		if strings.TrimSpace(lines[i]) == "---" {
			// Found closing YAML delimiter, return content after it
			if i+1 < len(lines) {
				return strings.Join(lines[i+1:], "\n")
			}

			return ""
		}
	}

	// No closing "---" found, return original content
	return content
}

// increaseHeaderLevels increases all markdown header levels by one.
func increaseHeaderLevels(content string) string {
	lines := strings.Split(content, "\n")
	var processedLines []string

	for _, line := range lines {
		trimmed := strings.TrimLeft(line, " \t")

		// Check if line starts with # and is a valid header
		if strings.HasPrefix(trimmed, "#") {
			// Find where the hashes end
			hashEnd := 0
			for i, char := range trimmed {
				if char == '#' {
					hashEnd = i + 1
				} else {
					break
				}
			}

			// Check if it's a valid header and process accordingly
			switch {
			case hashEnd < len(trimmed) && trimmed[hashEnd] == ' ':
				// Valid header with space - add one more #
				processedLines = append(processedLines, "#"+line)
			case hashEnd == len(trimmed):
				// Header with only hashes - add one more #
				processedLines = append(processedLines, "#"+line)
			default:
				// Not a valid header
				processedLines = append(processedLines, line)
			}
		} else {
			processedLines = append(processedLines, line)
		}
	}

	return strings.Join(processedLines, "\n")
}

// getMarkdownFiles returns all markdown files in the specified directory.
func getMarkdownFiles(directory string) ([]string, error) {
	var markdownFiles []string

	// Check if directory exists
	if _, err := os.Stat(directory); os.IsNotExist(err) {
		return nil, fmt.Errorf("directory '%s' does not exist", directory)
	}

	// Walk through directory and find markdown files
	err := filepath.WalkDir(directory, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		// Skip subdirectories - only process files in the specified directory
		if d.IsDir() && path != directory {
			return filepath.SkipDir
		}

		// Check if file has markdown extension
		ext := strings.ToLower(filepath.Ext(path))
		if ext == ".md" || ext == ".markdown" {
			markdownFiles = append(markdownFiles, path)
		}

		return nil
	})

	if err != nil {
		return nil, fmt.Errorf("error reading directory: %v", err)
	}

	// Sort files alphabetically for consistent ordering
	sort.Strings(markdownFiles)

	return markdownFiles, nil
}

// processMarkdownFile processes a single markdown file.
func processMarkdownFile(filePath string) (string, string, error) {
	// Read file content
	content, err := os.ReadFile(filePath)
	if err != nil {
		return "", "", fmt.Errorf("error reading file: %v", err)
	}

	contentStr := string(content)

	// Remove YAML front matter
	contentStr = removeYAMLFrontmatter(contentStr)

	// Increase header levels
	contentStr = increaseHeaderLevels(contentStr)

	// Strip leading/trailing whitespace
	contentStr = strings.TrimSpace(contentStr)

	// Get filename without extension
	filename := strings.TrimSuffix(filepath.Base(filePath), filepath.Ext(filePath))

	return filename, contentStr, nil
}

// combineMarkdownFiles combines all markdown files in a directory into a single file.
func (mc *MarkdownCombiner) combineMarkdownFiles() error {
	// Get all markdown files
	markdownFiles, err := getMarkdownFiles(mc.inputDir)
	if err != nil {
		return err
	}

	if len(markdownFiles) == 0 {
		fmt.Printf("No markdown files found in '%s'\n", mc.inputDir)

		return nil
	}

	fmt.Printf("Found %d markdown files\n", len(markdownFiles))

	// Process each file and combine content
	var combinedContent strings.Builder

	for _, filePath := range markdownFiles {
		fmt.Printf("Processing: %s\n", filepath.Base(filePath))

		filename, content, err := processMarkdownFile(filePath)
		if err != nil {
			fmt.Printf("Error processing %s: %v\n", filepath.Base(filePath), err)

			continue
		}

		// Add filename as H1 header
		combinedContent.WriteString(fmt.Sprintf("# %s\n\n", filename))

		// Add processed content if it's not empty
		if content != "" {
			combinedContent.WriteString(content)
			combinedContent.WriteString("\n\n")
		} else {
			combinedContent.WriteString("*This file was empty or contained only YAML front matter.*\n\n")
		}
	}

	// Create output directory if it doesn't exist
	outputDir := filepath.Dir(mc.outputFile)
	if outputDir != "." && outputDir != "" {
		err = os.MkdirAll(outputDir, 0755)
		if err != nil {
			return fmt.Errorf("error creating output directory: %v", err)
		}
	}

	// Write combined content to output file
	//nolint:gosec
	err = os.WriteFile(mc.outputFile, []byte(combinedContent.String()), 0644)
	if err != nil {
		return fmt.Errorf("error writing output file: %v", err)
	}

	fmt.Printf("Successfully combined %d files into '%s'\n", len(markdownFiles), mc.outputFile)

	return nil
}

// printUsage prints detailed usage information.
func printUsage() {
	fmt.Fprintf(os.Stderr, `Markdown File Combiner

Combines all markdown files in a directory into a single file.

Usage:
  %s [options] <input_directory> [output_file]

Arguments:
  input_directory    Directory containing markdown files to combine
  output_file        Output file path (default: combined_markdown.md)

Options:
  -o, -output string    Alternative way to specify output file
  -h, -help            Show this help message

Examples:
  %s docs/ combined.md
  %s /path/to/markdown/files output/all_docs.md
  %s . -o merged_documentation.md

The program will:
- Find all .md and .markdown files in the input directory
- Remove YAML front matter from each file
- Add the filename as an H1 header
- Increase all existing header levels by one
- Combine everything into a single output file

`, os.Args[0], os.Args[0], os.Args[0], os.Args[0])
}

func main() {
	// Define command line flags
	var outputFile string
	var showHelp bool

	flag.StringVar(&outputFile, "output", "", "Output file path")
	flag.StringVar(&outputFile, "o", "", "Output file path (shorthand)")
	flag.BoolVar(&showHelp, "help", false, "Show help message")
	flag.BoolVar(&showHelp, "h", false, "Show help message (shorthand)")

	// Custom usage function
	flag.Usage = printUsage

	// Parse command line flags
	flag.Parse()

	// Show help if requested
	if showHelp {
		printUsage()
		os.Exit(0)
	}

	// Get non-flag arguments
	args := flag.Args()

	// Validate arguments
	if len(args) < 1 {
		fmt.Fprintf(os.Stderr, "Error: Input directory is required\n\n")
		printUsage()
		os.Exit(1)
	}

	inputDir := args[0]

	// Determine output file
	defaultOutput := "combined_markdown.md"
	finalOutput := defaultOutput

	// Priority: -o flag > positional argument > default
	if outputFile != "" {
		finalOutput = outputFile
	} else if len(args) > 1 {
		finalOutput = args[1]
	}

	// Create combiner and execute
	combiner := &MarkdownCombiner{
		inputDir:   inputDir,
		outputFile: finalOutput,
	}

	err := combiner.combineMarkdownFiles()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}
