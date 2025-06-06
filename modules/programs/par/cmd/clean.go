package cmd

import (
	"fmt"
	"log/slog"
	"time"

	"github.com/spf13/cobra"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/config"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/results"
)

var cleanCmd = &cobra.Command{
	Use:   "clean [--all] [--failed]",
	Short: "Clean up temporary files and failed runs",
	Long: `Clean up temporary files, failed run artifacts, and other cleanup operations.
Use --all to clean everything, or --failed to clean only failed runs.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		all, err := cmd.Flags().GetBool("all")
		if err != nil {
			return fmt.Errorf("failed to parse 'all' flag: %w", err)
		}
		failed, err := cmd.Flags().GetBool("failed")
		if err != nil {
			return fmt.Errorf("failed to parse 'failed' flag: %w", err)
		}
		maxAge, err := cmd.Flags().GetString("max-age")
		if err != nil {
			return fmt.Errorf("failed to parse 'max-age' flag: %w", err)
		}

		// Load configuration
		cfg, err := config.Load()
		if err != nil {
			return fmt.Errorf("failed to load configuration: %w", err)
		}

		storage := results.NewStorage(cfg.Defaults.OutputDir)

		if all {
			slog.Info("Cleaning all result files")
			
			// Parse max age
			age := 7 * 24 * time.Hour // Default to 7 days
			if maxAge != "" {
				if parsedAge, err := time.ParseDuration(maxAge); err == nil {
					age = parsedAge
				} else {
					return fmt.Errorf("invalid max-age duration: %w", err)
				}
			}
			
			if err := storage.CleanOldResults(age); err != nil {
				return fmt.Errorf("failed to clean results: %w", err)
			}
			
			slog.Info("Cleaned result files", "max_age", age)
			
		} else if failed {
			slog.Info("Cleaning failed run artifacts")
			
			// List summaries and find failed ones
			summaries, err := storage.ListSummaries()
			if err != nil {
				return fmt.Errorf("failed to list summaries: %w", err)
			}
			
			cleanedCount := 0
			for _, summaryFile := range summaries {
				summary, err := storage.LoadSummary(summaryFile)
				if err != nil {
					continue // Skip invalid files
				}
				
				if summary.HasFailures() {
					slog.Info("Cleaning failed run", 
						"file", summaryFile, 
						"failures", summary.FailedJobs)
					
					if err := storage.DeleteFailedRun(summaryFile); err != nil {
						slog.Warn("Failed to delete failed run", 
						"file", summaryFile, 
						"error", err)
						continue
					}
					cleanedCount++
				}
			}
			
			if cleanedCount == 0 {
				slog.Info("No failed runs found")
			} else {
				slog.Info("Cleaned failed runs", "count", cleanedCount)
			}
			
		} else {
			slog.Info("Cleaning default temporary files", "max_age", "30 days")
			
			age := 30 * 24 * time.Hour // Default to 30 days
			if err := storage.CleanOldResults(age); err != nil {
				return fmt.Errorf("failed to clean results: %w", err)
			}
			
			slog.Info("Cleaned result files", "max_age", age)
		}

		return nil
	},
}

func init() {
	cleanCmd.Flags().Bool("all", false, "Clean all temporary files and artifacts")
	cleanCmd.Flags().Bool("failed", false, "Clean only failed run artifacts")
	cleanCmd.Flags().String("max-age", "", "Maximum age for files to keep (e.g., 7d, 24h)")
}