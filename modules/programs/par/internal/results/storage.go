package results

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// Storage handles persisting results to disk
type Storage struct {
	outputDir string
}

// NewStorage creates a new result storage instance
func NewStorage(outputDir string) *Storage {
	return &Storage{
		outputDir: outputDir,
	}
}

// SaveSummary saves a summary to disk with multiple formats
func (s *Storage) SaveSummary(summary *Summary, sessionID string) error {
	if err := s.ensureOutputDir(); err != nil {
		return err
	}

	timestamp := time.Now().Format("20060102_150405")
	baseFilename := fmt.Sprintf("par_results_%s_%s", timestamp, sessionID[:8])

	reporter := NewReporter()

	// Save JSON report
	jsonReport, err := reporter.GenerateJSONReport(summary)
	if err != nil {
		return fmt.Errorf("failed to generate JSON report: %w", err)
	}

	if err := s.saveFile(baseFilename+".json", jsonReport); err != nil {
		return fmt.Errorf("failed to save JSON report: %w", err)
	}

	// Save console report
	consoleReport := reporter.GenerateConsoleReport(summary)
	if err := s.saveFile(baseFilename+".txt", consoleReport); err != nil {
		return fmt.Errorf("failed to save console report: %w", err)
	}

	// Save detailed report
	detailedReport := reporter.GenerateDetailedReport(summary)
	if err := s.saveFile(baseFilename+"_detailed.txt", detailedReport); err != nil {
		return fmt.Errorf("failed to save detailed report: %w", err)
	}

	// Save CSV report
	csvReport := reporter.GenerateCSVReport(summary)
	if err := s.saveFile(baseFilename+".csv", csvReport); err != nil {
		return fmt.Errorf("failed to save CSV report: %w", err)
	}

	return nil
}

// SaveIndividualResults saves individual job outputs to separate files
func (s *Storage) SaveIndividualResults(summary *Summary, sessionID string) error {
	if err := s.ensureOutputDir(); err != nil {
		return err
	}

	timestamp := time.Now().Format("20060102_150405")
	outputsDir := filepath.Join(s.outputDir, fmt.Sprintf("outputs_%s_%s", timestamp, sessionID[:8]))

	if err := os.MkdirAll(outputsDir, 0755); err != nil {
		return fmt.Errorf("failed to create outputs directory: %w", err)
	}

	for _, result := range summary.Results {
		if result.Output == "" {
			continue
		}

		// Create filename from worktree path
		filename := s.sanitizeFilename(filepath.Base(result.Worktree)) + ".txt"
		filepath := filepath.Join(outputsDir, filename)

		content := fmt.Sprintf("Job ID: %s\n", result.JobID)
		content += fmt.Sprintf("Worktree: %s\n", result.Worktree)
		content += fmt.Sprintf("Status: %s\n", result.Status)
		content += fmt.Sprintf("Duration: %s\n", result.Duration)
		content += fmt.Sprintf("Start Time: %s\n", result.StartTime.Format(time.RFC3339))
		content += fmt.Sprintf("End Time: %s\n", result.EndTime.Format(time.RFC3339))
		content += "\n" + strings.Repeat("=", 50) + "\n\n"
		content += result.Output

		if err := os.WriteFile(filepath, []byte(content), 0644); err != nil {
			return fmt.Errorf("failed to save output for %s: %w", result.Worktree, err)
		}
	}

	return nil
}

// LoadSummary loads a previously saved summary
func (s *Storage) LoadSummary(filename string) (*Summary, error) {
	filepath := filepath.Join(s.outputDir, filename)

	data, err := os.ReadFile(filepath)
	if err != nil {
		return nil, fmt.Errorf("failed to read summary file: %w", err)
	}

	var summary Summary
	if err := json.Unmarshal(data, &summary); err != nil {
		return nil, fmt.Errorf("failed to parse summary file: %w", err)
	}

	return &summary, nil
}

// ListSummaries lists all available summary files
func (s *Storage) ListSummaries() ([]string, error) {
	if _, err := os.Stat(s.outputDir); os.IsNotExist(err) {
		return []string{}, nil
	}

	files, err := os.ReadDir(s.outputDir)
	if err != nil {
		return nil, fmt.Errorf("failed to read output directory: %w", err)
	}

	var summaries []string
	for _, file := range files {
		if !file.IsDir() && filepath.Ext(file.Name()) == ".json" &&
			strings.HasPrefix(file.Name(), "par_results_") {
			summaries = append(summaries, file.Name())
		}
	}

	return summaries, nil
}

// CleanOldResults removes old result files based on age
func (s *Storage) CleanOldResults(maxAge time.Duration) error {
	if _, err := os.Stat(s.outputDir); os.IsNotExist(err) {
		return nil
	}

	files, err := os.ReadDir(s.outputDir)
	if err != nil {
		return fmt.Errorf("failed to read output directory: %w", err)
	}

	cutoff := time.Now().Add(-maxAge)

	for _, file := range files {
		info, err := file.Info()
		if err != nil {
			continue
		}

		if info.ModTime().Before(cutoff) {
			filepath := filepath.Join(s.outputDir, file.Name())
			if err := os.Remove(filepath); err != nil {
				// Log but continue
				fmt.Printf("Warning: failed to remove old file %s: %v\n", filepath, err)
			}
		}
	}

	return nil
}

// DeleteFailedRun removes all files associated with a failed run
func (s *Storage) DeleteFailedRun(summaryFilename string) error {
	// Extract base name from summary filename
	baseName := strings.TrimSuffix(summaryFilename, ".json")

	// List of file extensions to clean up
	extensions := []string{".json", ".txt", "_detailed.txt", ".csv"}

	for _, ext := range extensions {
		filename := baseName + ext
		filepath := filepath.Join(s.outputDir, filename)
		if err := os.Remove(filepath); err != nil && !os.IsNotExist(err) {
			return fmt.Errorf("failed to remove file %s: %w", filename, err)
		}
	}

	// Also try to remove associated outputs directory
	outputsDir := strings.Replace(baseName, "par_results_", "outputs_", 1)
	outputsDirPath := filepath.Join(s.outputDir, outputsDir)
	if err := os.RemoveAll(outputsDirPath); err != nil && !os.IsNotExist(err) {
		return fmt.Errorf("failed to remove outputs directory %s: %w", outputsDir, err)
	}

	return nil
}

// ensureOutputDir ensures the output directory exists
func (s *Storage) ensureOutputDir() error {
	return os.MkdirAll(s.outputDir, 0755)
}

// saveFile saves content to a file in the output directory
func (s *Storage) saveFile(filename, content string) error {
	filepath := filepath.Join(s.outputDir, filename)
	return os.WriteFile(filepath, []byte(content), 0644)
}

// sanitizeFilename removes invalid characters from filenames
func (s *Storage) sanitizeFilename(name string) string {
	invalid := []string{"/", "\\", ":", "*", "?", "\"", "<", ">", "|"}
	result := name
	for _, char := range invalid {
		result = strings.ReplaceAll(result, char, "_")
	}
	return result
}
