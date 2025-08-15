// Package catls provides the core functionality for the catls application.
package catls

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/connerosiu/dotfiles/modules/programs/catls/internal/scanner"
)

// Config holds all configuration options for catls.
type Config struct {
	Directory       string
	Files           []string
	ShowAll         bool
	Recursive       bool
	Debug           bool
	IgnoreDir       []string
	Globs           []string
	IgnoreGlobs     []string
	ContentPattern  string
	ShowLineNumbers bool
	OmitBins        bool
	OutputFormat    OutputFormat
}

// defaultIgnoreGlobs returns standard ignore patterns.
func (c *Config) defaultIgnoreGlobs() []string {
	return []string{
		".git/*", ".svn/*", ".hg/*",
		"__pycache__/*", ".pytest_cache/*", ".mypy_cache/*",
		".tox/*", ".venv/*", ".coverage",
		".DS_Store", ".idea/*", ".vscode/*",
		"*_templ.go", "LICENSE", "LICENSE.md", "LICENSE.txt",
	}
}

// AllIgnoreGlobs combines default and user-specified ignore patterns.
func (c *Config) AllIgnoreGlobs() []string {
	return append(c.defaultIgnoreGlobs(), c.IgnoreGlobs...)
}

// App represents the main catls application.
type App struct {
	cfg       *Config
	scanner   *scanner.Scanner
	filter    *FileFilter
	processor *FileProcessor
	output    OutputFormatter
}

// New creates a new catls application instance.
func New(cfg *Config) *App {
	output, err := NewOutputFormatter(cfg.OutputFormat)
	if err != nil {
		// This should not happen if config validation is working correctly
		panic(fmt.Sprintf("failed to create output formatter: %v", err))
	}

	return &App{
		cfg:       cfg,
		scanner:   scanner.New(),
		filter:    NewFileFilter(cfg),
		processor: NewFileProcessor(),
		output:    output,
	}
}

// Run executes the catls operation.
func (a *App) Run(ctx context.Context) error {
	if err := a.validateConfig(); err != nil {
		return err
	}

	if a.cfg.Debug {
		fmt.Fprintf(os.Stderr, "Debug: Ignoring directories: %v\n", a.cfg.IgnoreDir)
	}

	// Add files to globs if specified
	a.addFilesToGlobs()

	// Scan for files
	scanCfg := scanner.Config{
		Directory:   a.cfg.Directory,
		ShowAll:     a.cfg.ShowAll,
		Recursive:   a.cfg.Recursive,
		IgnoreDir:   a.cfg.IgnoreDir,
		IgnoreGlobs: a.cfg.AllIgnoreGlobs(),
		Debug:       a.cfg.Debug,
	}

	files, err := a.scanner.Scan(ctx, scanCfg)
	if err != nil {
		return fmt.Errorf("failed to scan files: %w", err)
	}

	if len(files) == 0 {
		fmt.Printf("No files found in directory: %s\n", a.cfg.Directory)
		return nil
	}

	// Process and output files
	return a.processAndOutput(ctx, files)
}

// validateConfig ensures the configuration is valid.
func (a *App) validateConfig() error {
	if _, err := os.Stat(a.cfg.Directory); os.IsNotExist(err) {
		return fmt.Errorf("directory '%s' does not exist", a.cfg.Directory)
	}

	// Normalize ignore directories
	for i, dir := range a.cfg.IgnoreDir {
		a.cfg.IgnoreDir[i] = strings.TrimSuffix(dir, "/")
	}

	return nil
}

// addFilesToGlobs converts specific file arguments to glob patterns.
func (a *App) addFilesToGlobs() {
	for _, file := range a.cfg.Files {
		if _, err := os.Stat(file); err == nil {
			// File exists, use its basename as pattern
			a.cfg.Globs = append(a.cfg.Globs, filepath.Base(file))
		} else {
			// File doesn't exist, treat as pattern
			a.cfg.Globs = append(a.cfg.Globs, file)
		}
	}
}

// processAndOutput handles file processing and output generation.
func (a *App) processAndOutput(ctx context.Context, files []scanner.FileInfo) error {
	// Write header
	if err := a.output.WriteHeader(ctx); err != nil {
		return fmt.Errorf("failed to write output header: %w", err)
	}

	for _, file := range files {
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
		}

		// Apply file filtering
		if !a.filter.ShouldIncludeFile(file, a.cfg) {
			continue
		}

		// Create filter for this specific file processing
		filter := NewFileFilter(a.cfg)
		
		// Process the file
		processed := a.processor.ProcessFile(file, filter)

		// Write processed file using the output formatter
		if err := a.output.WriteFile(ctx, processed, a.cfg); err != nil {
			return fmt.Errorf("failed to write file %s: %w", file.RelPath, err)
		}
	}

	// Write footer
	if err := a.output.WriteFooter(ctx); err != nil {
		return fmt.Errorf("failed to write output footer: %w", err)
	}

	return nil
}