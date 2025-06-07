package cmd

import (
	"fmt"
	"log/slog"
	"runtime"
	"time"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/config"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/executor"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/prompts"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/results"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/worktree"
	"github.com/google/uuid"
	"github.com/spf13/cobra"
)

var runCmd = &cobra.Command{
	Use:   "run <prompt-name> [options]",
	Short: "Run a prompt across multiple worktrees",
	Long: `Execute a prompt across multiple Git worktree branches/directories 
simultaneously. This is the core functionality of par.`,
	Args: cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		promptName := args[0]

		// Parse flags
		jobs, _ := cmd.Flags().GetInt("jobs")
		worktreePattern, _ := cmd.Flags().GetString("worktrees")
		directories, _ := cmd.Flags().GetStringSlice("directories")
		timeoutStr, _ := cmd.Flags().GetString("timeout")
		outputDir, _ := cmd.Flags().GetString("output")
		dryRun, _ := cmd.Flags().GetBool("dry-run")
		continueOnFailure, _ := cmd.Flags().GetBool("continue-on-failure")
		templateVarStrs, _ := cmd.Flags().GetStringSlice("template-vars")
		ghostty, _ := cmd.Flags().GetBool("ghostty")
		terminalOutput, _ := cmd.Flags().GetBool("terminal-output")

		// Parse timeout
		timeout, err := time.ParseDuration(timeoutStr)
		if err != nil {
			return fmt.Errorf("invalid timeout duration: %w", err)
		}

		// Load configuration
		cfg, err := config.Load()
		if err != nil {
			return fmt.Errorf("failed to load configuration: %w", err)
		}

		// Ensure directories exist
		err = cfg.EnsureDirectories()
		if err != nil {
			return fmt.Errorf("failed to create directories: %w", err)
		}

		// Override output directory if specified
		if outputDir != "" {
			cfg.Defaults.OutputDir = outputDir
		}

		// Load prompt
		promptManager := prompts.NewManager(cfg.Prompts.StorageDir)
		prompt, err := promptManager.Load(promptName)
		if err != nil {
			return fmt.Errorf("failed to load prompt: %w", err)
		}

		// Parse template variables
		templateVars, err := prompts.ParseTemplateVars(templateVarStrs)
		if err != nil {
			return fmt.Errorf("failed to parse template variables: %w", err)
		}

		// Process template
		processedPrompt, err := prompts.ProcessTemplate(prompt, templateVars)
		if err != nil {
			return fmt.Errorf("failed to process template: %w", err)
		}

		// Discover worktrees
		var targetWorktrees []*worktree.Worktree

		if len(directories) > 0 {
			// Use specified directories
			for _, dir := range directories {
				wt := &worktree.Worktree{
					Name: fmt.Sprintf("custom-%d", len(targetWorktrees)),
					Path: dir,
				}
				targetWorktrees = append(targetWorktrees, wt)
			}
		} else {
			// Discover worktrees
			discovery := worktree.NewDiscovery(cfg.Worktrees.SearchPaths, cfg.Worktrees.ExcludePatterns)
			discoveredWorktrees, err := discovery.FindWorktrees()
			if err != nil {
				return fmt.Errorf("failed to discover worktrees: %w", err)
			}

			// Filter by pattern if specified
			if worktreePattern != "" {
				manager := worktree.NewManager(cfg)
				filteredWorktrees, err := manager.FilterByPattern(discoveredWorktrees, worktreePattern)
				if err != nil {
					return fmt.Errorf("failed to filter worktrees: %w", err)
				}
				targetWorktrees = filteredWorktrees
			} else {
				targetWorktrees = discoveredWorktrees
			}
		}

		// Validate worktrees
		validator := worktree.NewValidator(cfg)
		validWorktrees := validator.FilterValid(targetWorktrees)

		if len(validWorktrees) == 0 {
			return fmt.Errorf("no valid worktrees found")
		}

		slog.Info("Worktree discovery completed",
			"valid_count", len(validWorktrees),
			"discovered_count", len(targetWorktrees))
		fmt.Printf("Found %d valid worktrees (out of %d discovered)\n",
			len(validWorktrees), len(targetWorktrees))

		// Show what would be executed in dry run mode
		if dryRun {
			fmt.Printf("\nDry run - would execute on the following worktrees:\n")
			for _, wt := range validWorktrees {
				fmt.Printf("  - %s (%s) [%s]\n", wt.Name, wt.Path, wt.Branch)
			}
			fmt.Printf("\nPrompt to execute:\n%s\n", processedPrompt)
			return nil
		}

		// Create jobs
		var jobList []*executor.Job
		for _, wt := range validWorktrees {
			job := executor.NewJob(wt, processedPrompt, timeout)
			jobList = append(jobList, job)
		}

		slog.Info("Starting job execution",
			"job_count", len(jobList),
			"worker_count", jobs)
		fmt.Printf("Executing %d jobs with %d workers...\n", len(jobList), jobs)

		// Execute jobs
		pool, err := executor.NewPool(jobs, cfg)
		if err != nil {
			return err
		}
		var jobResults []*executor.JobResult

		if len(jobList) == 1 {
			// Use sequential execution for single job or debugging
			jobResults, err = pool.ExecuteSequential(jobList)
		} else {
			// Use parallel execution
			jobResults, err = pool.Execute(jobList)
		}

		if err != nil && !continueOnFailure {
			return fmt.Errorf("execution failed: %w", err)
		}

		// Process results
		aggregator := results.NewAggregator()
		summary := aggregator.ProcessResults(jobResults)

		// Generate and display report
		reporter := results.NewReporter()
		consoleReport := reporter.GenerateConsoleReport(summary)
		fmt.Print(consoleReport)

		// Save results
		sessionID := uuid.New().String()
		storage := results.NewStorage(cfg.Defaults.OutputDir)

		if err := storage.SaveSummary(summary, sessionID); err != nil {
			slog.Warn("Failed to save results", "error", err)
			fmt.Printf("Warning: failed to save results: %v\n", err)
		} else {
			slog.Info("Results saved successfully", "output_dir", cfg.Defaults.OutputDir)
			fmt.Printf("\nResults saved to: %s\n", cfg.Defaults.OutputDir)
		}

		// Save individual outputs if requested
		if terminalOutput || ghostty {
			if err := storage.SaveIndividualResults(summary, sessionID); err != nil {
				slog.Warn("Failed to save individual outputs", "error", err)
				fmt.Printf("Warning: failed to save individual outputs: %v\n", err)
			}
		}

		// Exit with error code if there were failures and continue-on-failure is not set
		if summary.HasFailures() && !continueOnFailure {
			return fmt.Errorf("execution completed with %d failures", summary.FailedJobs)
		}

		return nil
	},
}

func init() {
	runCmd.Flags().IntP("jobs", "j", runtime.NumCPU(), "Number of parallel jobs")
	runCmd.Flags().StringP("worktrees", "w", "", "Filter worktrees by pattern")
	runCmd.Flags().StringSliceP("directories", "d", []string{}, "Specify custom directories")
	runCmd.Flags().StringP("timeout", "t", "30m", "Timeout per job")
	runCmd.Flags().StringP("output", "o", "", "Output directory for results")
	runCmd.Flags().Bool("dry-run", false, "Show what would be executed")
	runCmd.Flags().Bool("continue-on-failure", false, "Continue even if some jobs fail")
	runCmd.Flags().StringSlice("template-vars", []string{}, "Template variable substitution (key=val)")
	runCmd.Flags().Bool("ghostty", false, "Open each job in separate Ghostty window")
	runCmd.Flags().Bool("terminal-output", false, "Show real-time terminal output")
}
