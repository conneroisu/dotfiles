// Package scanner handles file discovery and analysis.
package scanner

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

// FileInfo represents information about a discovered file.
type FileInfo struct {
	Path     string
	RelPath  string
	IsBinary bool
}

// Config holds scanner configuration.
type Config struct {
	Directory   string
	ShowAll     bool
	Recursive   bool
	IgnoreDir   []string
	IgnoreGlobs []string
	Debug       bool
}

// Scanner handles file discovery and filtering.
type Scanner struct {
	binaryDetector BinaryDetector
}

// New creates a new scanner.
func New() *Scanner {
	return &Scanner{
		binaryDetector: &FileBinaryDetector{},
	}
}

// Scan discovers files according to configuration.
func (s *Scanner) Scan(ctx context.Context, cfg Config) ([]FileInfo, error) {
	var files []FileInfo
	maxDepth := 1
	if cfg.Recursive {
		maxDepth = -1
	}

	type dirEntry struct {
		path  string
		depth int
	}

	stack := []dirEntry{{cfg.Directory, 0}}

	for len(stack) > 0 {
		select {
		case <-ctx.Done():
			return nil, ctx.Err()
		default:
		}

		current := stack[len(stack)-1]
		stack = stack[:len(stack)-1]

		if maxDepth != -1 && current.depth >= maxDepth {
			continue
		}

		entries, err := os.ReadDir(current.path)
		if err != nil {
			if cfg.Debug {
				fmt.Fprintf(os.Stderr, "Error accessing directory %s: %v\n", current.path, err)
			}
			continue
		}

		// Sort entries for consistent output
		var entryNames []string
		for _, entry := range entries {
			entryNames = append(entryNames, entry.Name())
		}
		sort.Strings(entryNames)

		for _, entryName := range entryNames {
			if entryName == "." || entryName == ".." {
				continue
			}

			if !cfg.ShowAll && strings.HasPrefix(entryName, ".") {
				continue
			}

			fullPath := filepath.Join(current.path, entryName)
			
			info, err := os.Stat(fullPath)
			if err != nil {
				continue
			}

			if info.IsDir() {
				if !s.shouldIgnoreDir(fullPath, cfg) {
					stack = append(stack, dirEntry{fullPath, current.depth + 1})
				} else if cfg.Debug {
					fmt.Fprintf(os.Stderr, "Debug: Ignoring directory: %s\n", fullPath)
				}
			} else if info.Mode().IsRegular() {
				relPath, err := s.getRelativePath(fullPath, cfg.Directory)
				if err != nil {
					continue
				}

				isBinary := s.binaryDetector.IsBinary(fullPath)
				
				files = append(files, FileInfo{
					Path:     fullPath,
					RelPath:  relPath,
					IsBinary: isBinary,
				})
			}
		}
	}

	sort.Slice(files, func(i, j int) bool {
		return files[i].RelPath < files[j].RelPath
	})

	return files, nil
}

// getRelativePath returns the relative path from base directory.
func (s *Scanner) getRelativePath(fullPath, baseDir string) (string, error) {
	if baseDir == "." {
		return fullPath, nil
	}
	
	return filepath.Rel(baseDir, fullPath)
}