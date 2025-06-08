// Package results handles result aggregation and reporting
package results

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/config"
)

// Manager handles result operations
type Manager struct {
	config    *config.Config
	outputDir string
}

// NewManager creates a new results manager
func NewManager(cfg *config.Config) (*Manager, error) {
	outputDir := cfg.GetOutputDir()
	
	// Ensure output directory exists
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create output directory: %w", err)
	}

	return &Manager{
		config:    cfg,
		outputDir: outputDir,
	}, nil
}

// SaveResults saves job results to storage
func (m *Manager) SaveResults(sessionID string, results []interface{}) error {
	// Create session directory
	sessionDir := filepath.Join(m.outputDir, sessionID)
	if err := os.MkdirAll(sessionDir, 0755); err != nil {
		return fmt.Errorf("failed to create session directory: %w", err)
	}

	// Save results as JSON
	resultsFile := filepath.Join(sessionDir, "results.json")
	data, err := json.MarshalIndent(results, "", "  ")
	if err != nil {
		return fmt.Errorf("failed to marshal results: %w", err)
	}

	if err := os.WriteFile(resultsFile, data, 0644); err != nil {
		return fmt.Errorf("failed to write results file: %w", err)
	}

	// Save summary
	summary := m.generateSummary(results)
	summaryFile := filepath.Join(sessionDir, "summary.txt")
	if err := os.WriteFile(summaryFile, []byte(summary), 0644); err != nil {
		return fmt.Errorf("failed to write summary file: %w", err)
	}

	return nil
}

// FindFailedArtifacts finds artifacts from failed job runs
func (m *Manager) FindFailedArtifacts() ([]string, error) {
	var artifacts []string

	// Walk through output directory
	err := filepath.Walk(m.outputDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil // Skip errors, continue walking
		}

		// Look for result files that indicate failures
		if info.Name() == "results.json" {
			data, err := os.ReadFile(path)
			if err != nil {
				return nil
			}

			var results []map[string]interface{}
			if err := json.Unmarshal(data, &results); err != nil {
				return nil
			}

			// Check if any results failed
			for _, result := range results {
				if status, ok := result["status"].(string); ok && status == "failed" {
					artifacts = append(artifacts, filepath.Dir(path))
					break
				}
			}
		}

		return nil
	})

	return artifacts, err
}

// generateSummary generates a text summary of results
func (m *Manager) generateSummary(results []interface{}) string {
	summary := fmt.Sprintf("Par Execution Summary - %s\n", time.Now().Format("2006-01-02 15:04:05"))
	summary += "========================================\n\n"

	total := len(results)
	successful := 0
	failed := 0

	for _, result := range results {
		if resultMap, ok := result.(map[string]interface{}); ok {
			if status, ok := resultMap["status"].(string); ok {
				if status == "success" {
					successful++
				} else {
					failed++
				}
			}
		}
	}

	summary += fmt.Sprintf("Total Jobs: %d\n", total)
	summary += fmt.Sprintf("Successful: %d\n", successful)
	summary += fmt.Sprintf("Failed: %d\n", failed)

	if failed > 0 {
		summary += "\nFailed Jobs:\n"
		for _, result := range results {
			if resultMap, ok := result.(map[string]interface{}); ok {
				if status, ok := resultMap["status"].(string); ok && status != "success" {
					worktree := "unknown"
					errorMsg := "unknown error"
					
					if w, ok := resultMap["worktree"].(string); ok {
						worktree = w
					}
					if e, ok := resultMap["error_message"].(string); ok {
						errorMsg = e
					}
					
					summary += fmt.Sprintf("- %s: %s\n", worktree, errorMsg)
				}
			}
		}
	}

	return summary
}

// GetResultsDirectory returns the results directory path
func (m *Manager) GetResultsDirectory() string {
	return m.outputDir
}

// CleanOldResults removes result files older than the specified duration
func (m *Manager) CleanOldResults(maxAge time.Duration) error {
	cutoff := time.Now().Add(-maxAge)

	return filepath.Walk(m.outputDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil // Skip errors
		}

		if info.IsDir() && info.ModTime().Before(cutoff) {
			// Check if this is a session directory (contains results.json)
			resultsPath := filepath.Join(path, "results.json")
			if _, err := os.Stat(resultsPath); err == nil {
				return os.RemoveAll(path)
			}
		}

		return nil
	})
}