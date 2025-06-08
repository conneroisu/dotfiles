package cmd

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/spf13/cobra"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/config"
)

var (
	cleanAll    bool
	cleanFailed bool
	cleanForce  bool
	cleanOld    string
)

var cleanCmd = &cobra.Command{
	Use:   "clean",
	Short: "Clean up temporary files and failed runs",
	Long: `Clean up temporary files, logs, and failed runs created by par.
This command helps maintain a clean workspace by removing old execution artifacts.

Examples:
  par clean                    # Clean up old temporary files (interactive)
  par clean --all              # Clean up all temporary files
  par clean --failed           # Clean up only failed runs
  par clean --force            # Skip confirmation prompts
  par clean --old=7d           # Clean files older than 7 days`,
	RunE: runClean,
}

func init() {
	cleanCmd.Flags().BoolVar(&cleanAll, "all", false, "Clean up all temporary files and logs")
	cleanCmd.Flags().BoolVar(&cleanFailed, "failed", false, "Clean up only failed runs")
	cleanCmd.Flags().BoolVarP(&cleanForce, "force", "f", false, "Force cleanup without confirmation")
	cleanCmd.Flags().StringVar(&cleanOld, "old", "30d", "Clean files older than specified duration (e.g., 7d, 24h)")
}

func runClean(cmd *cobra.Command, args []string) error {
	cfg := config.Get()
	
	// Parse the old duration
	cutoffDuration, err := time.ParseDuration(cleanOld)
	if err != nil {
		return fmt.Errorf("invalid duration format: %s", cleanOld)
	}
	cutoffTime := time.Now().Add(-cutoffDuration)
	
	// Get directories to clean
	outputDir := config.ExpandPath(cfg.Defaults.OutputDir)
	tempDir := filepath.Join(os.TempDir(), "par")
	
	var totalFiles int
	var totalSize int64
	
	fmt.Println("Par Cleanup Tool")
	fmt.Println("================")
	
	// Analyze what would be cleaned
	if cleanAll || !cleanFailed {
		files, size, err := analyzeDirectory(outputDir, cutoffTime, cleanAll)
		if err != nil {
			fmt.Printf("Warning: failed to analyze output directory: %v\n", err)
		} else {
			totalFiles += files
			totalSize += size
			if files > 0 {
				fmt.Printf("Output directory (%s): %d files, %s\n", 
					outputDir, files, formatBytes(size))
			}
		}
	}
	
	if cleanAll {
		files, size, err := analyzeDirectory(tempDir, cutoffTime, true)
		if err != nil {
			fmt.Printf("Warning: failed to analyze temp directory: %v\n", err)
		} else {
			totalFiles += files
			totalSize += size
			if files > 0 {
				fmt.Printf("Temp directory (%s): %d files, %s\n", 
					tempDir, files, formatBytes(size))
			}
		}
	}
	
	if cleanFailed {
		files, size, err := analyzeFailedRuns(outputDir, cutoffTime)
		if err != nil {
			fmt.Printf("Warning: failed to analyze failed runs: %v\n", err)
		} else {
			totalFiles += files
			totalSize += size
			if files > 0 {
				fmt.Printf("Failed runs: %d files, %s\n", files, formatBytes(size))
			}
		}
	}
	
	if totalFiles == 0 {
		fmt.Println("No files to clean up.")
		return nil
	}
	
	fmt.Printf("\nTotal: %d files, %s\n", totalFiles, formatBytes(totalSize))
	
	// Confirm deletion unless forced
	if !cleanForce {
		if !confirmCleanup() {
			fmt.Println("Cleanup cancelled.")
			return nil
		}
	}
	
	// Perform cleanup
	var cleanedFiles int
	var cleanedSize int64
	
	if cleanAll || !cleanFailed {
		files, size, err := cleanDirectory(outputDir, cutoffTime, cleanAll)
		if err != nil {
			fmt.Printf("Warning: failed to clean output directory: %v\n", err)
		} else {
			cleanedFiles += files
			cleanedSize += size
		}
	}
	
	if cleanAll {
		files, size, err := cleanDirectory(tempDir, cutoffTime, true)
		if err != nil {
			fmt.Printf("Warning: failed to clean temp directory: %v\n", err)
		} else {
			cleanedFiles += files
			cleanedSize += size
		}
	}
	
	if cleanFailed {
		files, size, err := cleanFailedRuns(outputDir, cutoffTime)
		if err != nil {
			fmt.Printf("Warning: failed to clean failed runs: %v\n", err)
		} else {
			cleanedFiles += files
			cleanedSize += size
		}
	}
	
	fmt.Printf("\nCleanup complete: removed %d files, freed %s\n", 
		cleanedFiles, formatBytes(cleanedSize))
	
	return nil
}

func analyzeDirectory(dir string, cutoffTime time.Time, includeAll bool) (int, int64, error) {
	if _, err := os.Stat(dir); os.IsNotExist(err) {
		return 0, 0, nil
	}
	
	var fileCount int
	var totalSize int64
	
	err := filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil // Skip files we can't access
		}
		
		if info.IsDir() {
			return nil
		}
		
		if includeAll || info.ModTime().Before(cutoffTime) {
			fileCount++
			totalSize += info.Size()
		}
		
		return nil
	})
	
	return fileCount, totalSize, err
}

func analyzeFailedRuns(dir string, cutoffTime time.Time) (int, int64, error) {
	if _, err := os.Stat(dir); os.IsNotExist(err) {
		return 0, 0, nil
	}
	
	var fileCount int
	var totalSize int64
	
	err := filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil
		}
		
		if info.IsDir() {
			return nil
		}
		
		// Look for failed run indicators (files with "failed" in name or .error extension)
		if (strings.Contains(strings.ToLower(info.Name()), "failed") ||
			strings.HasSuffix(strings.ToLower(info.Name()), ".error") ||
			strings.HasSuffix(strings.ToLower(info.Name()), ".err")) &&
			info.ModTime().Before(cutoffTime) {
			
			fileCount++
			totalSize += info.Size()
		}
		
		return nil
	})
	
	return fileCount, totalSize, err
}

func cleanDirectory(dir string, cutoffTime time.Time, includeAll bool) (int, int64, error) {
	if _, err := os.Stat(dir); os.IsNotExist(err) {
		return 0, 0, nil
	}
	
	var fileCount int
	var totalSize int64
	
	err := filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil
		}
		
		if info.IsDir() {
			// Try to remove empty directories
			if includeAll {
				if isEmpty, _ := isDirEmpty(path); isEmpty && path != dir {
					os.Remove(path)
				}
			}
			return nil
		}
		
		if includeAll || info.ModTime().Before(cutoffTime) {
			if err := os.Remove(path); err == nil {
				fileCount++
				totalSize += info.Size()
			}
		}
		
		return nil
	})
	
	return fileCount, totalSize, err
}

func cleanFailedRuns(dir string, cutoffTime time.Time) (int, int64, error) {
	if _, err := os.Stat(dir); os.IsNotExist(err) {
		return 0, 0, nil
	}
	
	var fileCount int
	var totalSize int64
	
	err := filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil
		}
		
		if info.IsDir() {
			return nil
		}
		
		if (strings.Contains(strings.ToLower(info.Name()), "failed") ||
			strings.HasSuffix(strings.ToLower(info.Name()), ".error") ||
			strings.HasSuffix(strings.ToLower(info.Name()), ".err")) &&
			info.ModTime().Before(cutoffTime) {
			
			if err := os.Remove(path); err == nil {
				fileCount++
				totalSize += info.Size()
			}
		}
		
		return nil
	})
	
	return fileCount, totalSize, err
}

func confirmCleanup() bool {
	fmt.Print("\nProceed with cleanup? (y/N): ")
	scanner := bufio.NewScanner(os.Stdin)
	scanner.Scan()
	response := strings.ToLower(strings.TrimSpace(scanner.Text()))
	return response == "y" || response == "yes"
}

func formatBytes(bytes int64) string {
	const unit = 1024
	if bytes < unit {
		return fmt.Sprintf("%d B", bytes)
	}
	div, exp := int64(unit), 0
	for n := bytes / unit; n >= unit; n /= unit {
		div *= unit
		exp++
	}
	return fmt.Sprintf("%.1f %cB", float64(bytes)/float64(div), "KMGTPE"[exp])
}

func isDirEmpty(name string) (bool, error) {
	f, err := os.Open(name)
	if err != nil {
		return false, err
	}
	defer f.Close()
	
	_, err = f.Readdirnames(1)
	if err == nil {
		return false, nil
	}
	return true, nil
}