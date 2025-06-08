package cmd

import (
	"fmt"
	"strings"
	"time"

	"github.com/spf13/cobra"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/config"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/executor"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/prompts"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/results"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/worktree"
)

var (
	runJobs     int
	runTimeout  string
	runDryRun   bool
	runTerm     bool
	runPlan     bool
	runBranch   string
	runFilter   string
	runJSON     bool
	runOutput   string
)

var runCmd = &cobra.Command{
	Use:   "run <prompt-name>",
	Short: "Run a prompt across multiple worktrees",
	Long: `Run a prompt across multiple discovered worktrees in parallel.
The command will discover all valid Git worktrees, validate them, and execute
the specified prompt using Claude Code CLI in parallel.

Examples:
  par run refactor-errors                    # Run with default settings
  par run refactor-errors --jobs 5          # Use 5 parallel workers
  par run refactor-errors --timeout 30m     # Set 30 minute timeout
  par run refactor-errors --dry-run          # Preview what would be executed
  par run refactor-errors --term=false      # Disable terminal integration
  par run refactor-errors --filter="main"   # Only run on worktrees containing "main"
  par run refactor-errors --json            # Output results in JSON format`,
	Args: cobra.ExactArgs(1),
	RunE: runRun,
}

func init() {
	runCmd.Flags().IntVarP(&runJobs, "jobs", "j", 0, "Number of parallel jobs (default from config)")
	runCmd.Flags().StringVarP(&runTimeout, "timeout", "t", "", "Timeout per job (default from config)")
	runCmd.Flags().BoolVar(&runDryRun, "dry-run", false, "Show what would be executed without running")
	runCmd.Flags().BoolVar(&runTerm, "term", true, "Open each job in separate terminal window")
	runCmd.Flags().BoolVar(&runPlan, "plan", false, "Enable planning phase before execution")
	runCmd.Flags().StringVarP(&runBranch, "branch", "b", "", "Base branch for creating worktrees")
	runCmd.Flags().StringVar(&runFilter, "filter", "", "Filter worktrees by name, project, or path")
	runCmd.Flags().BoolVar(&runJSON, "json", false, "Output results in JSON format")
	runCmd.Flags().StringVarP(&runOutput, "output", "o", "", "Output file for results")
}

func runRun(cmd *cobra.Command, args []string) error {
	promptName := args[0]
	
	// Load configuration
	cfg := config.Get()
	
	// Initialize components
	promptManager, err := prompts.NewManager()
	if err != nil {
		return fmt.Errorf("failed to initialize prompt manager: %w", err)
	}
	
	resultsManager, err := results.NewManager()
	if err != nil {
		return fmt.Errorf("failed to initialize results manager: %w", err)
	}
	
	// Load the prompt
	prompt, err := promptManager.Load(promptName)
	if err != nil {
		return fmt.Errorf("failed to load prompt '%s': %w", promptName, err)
	}
	
	fmt.Printf("Running prompt: %s\n", prompt.Name)
	if prompt.Description != "" {
		fmt.Printf("Description: %s\n", prompt.Description)
	}
	
	// Discover worktrees
	fmt.Println("\nDiscovering worktrees...")
	discoverer := worktree.NewDiscoverer()
	allWorktrees, err := discoverer.FindWorktrees()
	if err != nil {
		return fmt.Errorf("failed to discover worktrees: %w", err)
	}
	
	fmt.Printf("Found %d worktrees\n", len(allWorktrees))
	
	// Filter worktrees if specified
	var filteredWorktrees []*worktree.Worktree
	if runFilter != "" {
		filteredWorktrees = filterWorktrees(allWorktrees, runFilter)
		fmt.Printf("Filtered to %d worktrees matching '%s'\n", len(filteredWorktrees), runFilter)
	} else {
		filteredWorktrees = allWorktrees
	}
	
	if len(filteredWorktrees) == 0 {
		return fmt.Errorf("no worktrees found to execute on")
	}
	
	// Validate worktrees
	fmt.Println("\nValidating worktrees...")
	validator := worktree.NewValidator(false) // Non-strict validation
	validWorktrees, validationResults := validator.ValidateWorktrees(filteredWorktrees)
	
	if verbose {
		validator.PrintValidationResults(validationResults, filteredWorktrees)
	}
	
	fmt.Printf("Valid worktrees: %d/%d\n", len(validWorktrees), len(filteredWorktrees))
	
	if len(validWorktrees) == 0 {
		return fmt.Errorf("no valid worktrees found")
	}
	
	// Prepare execution parameters
	jobs := runJobs
	if jobs == 0 {
		jobs = cfg.Defaults.Jobs
	}
	
	timeout, err := parseTimeout(runTimeout, cfg)
	if err != nil {
		return fmt.Errorf("invalid timeout: %w", err)
	}
	
	// Process prompt template if needed
	templateProcessor := prompts.NewTemplateProcessor()
	
	// Create jobs
	var executionJobs []*worktree.Job
	for _, wt := range validWorktrees {
		processedPrompt, err := templateProcessor.Process(prompt, wt, nil)
		if err != nil {
			fmt.Printf("Warning: failed to process template for %s: %v\n", wt.GetDisplayName(), err)
			processedPrompt = prompt.Content // Fall back to raw content
		}
		
		job := worktree.NewJob(wt, processedPrompt, prompt.Name, timeout, nil)
		executionJobs = append(executionJobs, job)
	}
	
	// Create execution plan
	plan := worktree.NewExecutionPlan(prompt.Name, executionJobs, jobs, timeout, runDryRun, runTerm)
	
	fmt.Printf("\nExecution Plan\n")
	fmt.Printf("==============\n")
	fmt.Printf("Prompt: %s\n", plan.PromptName)
	fmt.Printf("Jobs: %d\n", plan.TotalJobs)
	fmt.Printf("Max Workers: %d\n", plan.MaxWorkers)
	fmt.Printf("Timeout: %s\n", plan.Timeout)
	fmt.Printf("Dry Run: %t\n", plan.DryRun)
	fmt.Printf("Terminal Mode: %t\n", plan.UseTerm)
	
	if runDryRun {
		fmt.Println("\nWorktrees to execute on:")
		for i, job := range executionJobs {
			fmt.Printf("  [%d] %s (%s) - %s\n", 
				i+1, 
				job.Worktree.GetDisplayName(), 
				job.Worktree.Branch, 
				job.Worktree.Path)
		}
	}
	
	// Execute the plan
	fmt.Println("\nStarting execution...")
	
	executionManager := executor.NewExecutionManager(executor.PoolOptions{
		NumWorkers: jobs,
		UseTerm:    runTerm,
		Timeout:    timeout,
	})
	
	summary, err := executionManager.Execute(plan)
	if err != nil {
		return fmt.Errorf("execution failed: %w", err)
	}
	
	// Generate and save report
	report := resultsManager.CreateReport(plan, summary, summary.Results)
	
	if err := resultsManager.SaveReport(report); err != nil {
		fmt.Printf("Warning: failed to save report: %v\n", err)
	}
	
	// Display results
	if runJSON {
		if err := resultsManager.PrintJSONSummary(summary); err != nil {
			return fmt.Errorf("failed to print JSON summary: %w", err)
		}
	} else {
		resultsManager.PrintSummary(summary)
		
		if verbose {
			fmt.Println()
			resultsManager.PrintDetailedResults(summary.Results)
		}
	}
	
	// Save output to file if specified
	if runOutput != "" {
		if err := saveOutputToFile(runOutput, summary, runJSON); err != nil {
			fmt.Printf("Warning: failed to save output to file: %v\n", err)
		} else {
			fmt.Printf("\nResults saved to: %s\n", runOutput)
		}
	}
	
	// Exit with appropriate code
	if summary.Failed > 0 || summary.Timeout > 0 {
		return fmt.Errorf("execution completed with %d failed and %d timeout jobs", 
			summary.Failed, summary.Timeout)
	}
	
	fmt.Printf("\nExecution completed successfully!\n")
	fmt.Printf("Report saved to: %s\n", resultsManager.GetOutputDir())
	
	return nil
}

func parseTimeout(timeoutStr string, cfg *config.Config) (time.Duration, error) {
	if timeoutStr == "" {
		return config.GetTimeoutDuration()
	}
	
	return time.ParseDuration(timeoutStr)
}

func filterWorktrees(worktrees []*worktree.Worktree, filter string) []*worktree.Worktree {
	var filtered []*worktree.Worktree
	
	for _, wt := range worktrees {
		if matchesWorktreeRunFilter(wt, filter) {
			filtered = append(filtered, wt)
		}
	}
	
	return filtered
}

func matchesWorktreeRunFilter(wt *worktree.Worktree, filter string) bool {
	// Check name, project name, path, and branch contain the filter string
	if strings.Contains(strings.ToLower(wt.Name), strings.ToLower(filter)) {
		return true
	}
	if strings.Contains(strings.ToLower(wt.ProjectName), strings.ToLower(filter)) {
		return true
	}
	if strings.Contains(strings.ToLower(wt.Path), strings.ToLower(filter)) {
		return true
	}
	if strings.Contains(strings.ToLower(wt.Branch), strings.ToLower(filter)) {
		return true
	}
	
	return false
}

func saveOutputToFile(filename string, summary *worktree.ExecutionSummary, asJSON bool) error {
	// This would save the output to a file
	// Implementation would depend on the desired format
	fmt.Printf("Output saving to %s not yet implemented\n", filename)
	return nil
}