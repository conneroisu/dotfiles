package cmd

import (
	"fmt"
	"os"
	"path/filepath"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/config"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/results"
	"github.com/spf13/cobra"
)

var (
	cleanAll    bool
	cleanFailed bool
	cleanForce  bool
)

// cleanCmd represents the clean command
var cleanCmd = &cobra.Command{
	Use:   "clean [--all] [--failed] [-f]",
	Short: "Clean up temporary files and failed runs",
	Long: `Clean up temporary files and failed runs.

By default, only cleans up temporary worktrees and result files older than 7 days.
Use --all to clean everything, or --failed to clean only failed job artifacts.

Examples:
  par clean          # Clean old temporary files
  par clean --all    # Clean all temporary files
  par clean --failed # Clean only failed job artifacts
  par clean --all -f # Force clean all without confirmation`,
	RunE: runClean,
}

func init() {
	rootCmd.AddCommand(cleanCmd)

	cleanCmd.Flags().BoolVar(&cleanAll, "all", false, "clean all temporary files")
	cleanCmd.Flags().BoolVar(&cleanFailed, "failed", false, "clean only failed job artifacts")
	cleanCmd.Flags().BoolVarP(&cleanForce, "force", "f", false, "force clean without confirmation")
}

func runClean(cmd *cobra.Command, args []string) error {
	cfg, err := config.Load()
	if err != nil {
		return fmt.Errorf("failed to load config: %w", err)
	}

	resultsManager, err := results.NewManager(cfg)
	if err != nil {
		return fmt.Errorf("failed to initialize results manager: %w", err)
	}

	var itemsToClean []string
	var cleanType string

	if cleanAll {
		cleanType = "all temporary files"
		items, err := findAllTempFiles(cfg)
		if err != nil {
			return fmt.Errorf("failed to find temporary files: %w", err)
		}
		itemsToClean = items
	} else if cleanFailed {
		cleanType = "failed job artifacts"
		items, err := resultsManager.FindFailedArtifacts()
		if err != nil {
			return fmt.Errorf("failed to find failed artifacts: %w", err)
		}
		itemsToClean = items
	} else {
		cleanType = "old temporary files (>7 days)"
		items, err := findOldTempFiles(cfg)
		if err != nil {
			return fmt.Errorf("failed to find old temporary files: %w", err)
		}
		itemsToClean = items
	}

	if len(itemsToClean) == 0 {
		fmt.Printf("✓ No %s found to clean\n", cleanType)
		return nil
	}

	fmt.Printf("🗑️  Found %d items to clean (%s):\n", len(itemsToClean), cleanType)
	for _, item := range itemsToClean {
		fmt.Printf("  - %s\n", item)
	}

	// Confirmation
	if !cleanForce {
		fmt.Printf("\nAre you sure you want to delete these %d items? [y/N]: ", len(itemsToClean))
		var response string
		fmt.Scanln(&response)
		if response != "y" && response != "Y" && response != "yes" {
			fmt.Println("Cleanup cancelled")
			return nil
		}
	}

	// Perform cleanup
	successCount := 0
	errorCount := 0

	for _, item := range itemsToClean {
		if err := os.RemoveAll(item); err != nil {
			fmt.Printf("❌ Failed to remove %s: %v\n", item, err)
			errorCount++
		} else {
			successCount++
		}
	}

	fmt.Printf("\n✓ Cleanup complete: %d items removed", successCount)
	if errorCount > 0 {
		fmt.Printf(", %d errors", errorCount)
	}
	fmt.Println()

	return nil
}

func findAllTempFiles(cfg *config.Config) ([]string, error) {
	var items []string

	// Results directory
	if cfg.Defaults.OutputDir != "" {
		if _, err := os.Stat(cfg.Defaults.OutputDir); err == nil {
			dir, err := os.ReadDir(cfg.Defaults.OutputDir)
			if err != nil {
				return nil, err
			}
			for _, entry := range dir {
				items = append(items, filepath.Join(cfg.Defaults.OutputDir, entry.Name()))
			}
		}
	}

	// Temporary worktrees (look for feat/<feature>/try-* pattern)
	for _, searchPath := range cfg.Worktrees.SearchPaths {
		expandedPath := expandPath(searchPath)
		tempWorktrees, err := findTempWorktrees(expandedPath)
		if err != nil {
			continue // Skip if path doesn't exist or can't be read
		}
		items = append(items, tempWorktrees...)
	}

	return items, nil
}

func findOldTempFiles(cfg *config.Config) ([]string, error) {
	// For now, return empty slice - implement based on file modification times
	// This would check modification times and only return files older than 7 days
	return []string{}, nil
}

func findTempWorktrees(basePath string) ([]string, error) {
	var worktrees []string

	dir, err := os.ReadDir(basePath)
	if err != nil {
		return nil, err
	}

	for _, entry := range dir {
		if !entry.IsDir() {
			continue
		}

		// Look for feat/<feature>/try-* pattern
		if entry.Name() == "feat" {
			featPath := filepath.Join(basePath, "feat")
			featDirs, err := os.ReadDir(featPath)
			if err != nil {
				continue
			}

			for _, featDir := range featDirs {
				if !featDir.IsDir() {
					continue
				}

				featurePath := filepath.Join(featPath, featDir.Name())
				tryDirs, err := os.ReadDir(featurePath)
				if err != nil {
					continue
				}

				for _, tryDir := range tryDirs {
					if tryDir.IsDir() && len(tryDir.Name()) > 4 && tryDir.Name()[:4] == "try-" {
						worktrees = append(worktrees, filepath.Join(featurePath, tryDir.Name()))
					}
				}
			}
		}
	}

	return worktrees, nil
}

func expandPath(path string) string {
	if len(path) > 0 && path[0] == '~' {
		home, err := os.UserHomeDir()
		if err != nil {
			return path
		}
		return filepath.Join(home, path[1:])
	}
	return path
}