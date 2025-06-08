package cmd

import (
	"fmt"
	"time"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/config"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/executor"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/prompts"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/worktree"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var (
	runJobs           int
	runTimeout        time.Duration
	runDryRun         bool
	runTerm           bool
	runTerminalOutput bool
	runBranch         string
	runPlan           bool
)

// runCmd represents the run command
var runCmd = &cobra.Command{
	Use:   "run <prompt-name> [options]",
	Short: "Run a prompt across multiple worktrees",
	Long: `Run a prompt across multiple Git worktrees in parallel.

This command will:
1. Discover available Git worktrees
2. Load the specified prompt
3. Execute Claude Code CLI in parallel across worktrees
4. Collect and report results

Example:
  par run refactor-errors --jobs 5 --timeout 30m`,
	Args: cobra.ExactArgs(1),
	RunE: runExecute,
}

func init() {
	rootCmd.AddCommand(runCmd)

	runCmd.Flags().IntVarP(&runJobs, "jobs", "j", 3, "number of parallel jobs")
	runCmd.Flags().DurationVarP(&runTimeout, "timeout", "t", 60*time.Minute, "timeout per job work stage")
	runCmd.Flags().BoolVar(&runDryRun, "dry-run", false, "show what would be executed")
	runCmd.Flags().BoolVar(&runTerm, "term", true, "open each job in separate terminal window")
	runCmd.Flags().BoolVar(&runTerminalOutput, "terminal-output", false, "show real-time terminal output")
	runCmd.Flags().StringVarP(&runBranch, "branch", "b", "main", "base branch for creating worktrees")
	runCmd.Flags().BoolVar(&runPlan, "plan", false, "enable planning phase before execution")
}

func runExecute(cmd *cobra.Command, args []string) error {
	promptName := args[0]

	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		return fmt.Errorf("failed to load config: %w", err)
	}

	// Override config with command line flags
	if cmd.Flags().Changed("jobs") {
		cfg.Defaults.Jobs = runJobs
	}
	if cmd.Flags().Changed("timeout") {
		cfg.Defaults.Timeout = runTimeout.String()
	}

	// Initialize prompt manager
	promptManager, err := prompts.NewManager()
	if err != nil {
		return fmt.Errorf("failed to initialize prompt manager: %w", err)
	}

	// Load prompt
	prompt, err := promptManager.Load(promptName)
	if err != nil {
		return fmt.Errorf("failed to load prompt '%s': %w", promptName, err)
	}

	// Initialize worktree manager
	worktreeManager, err := worktree.NewManager(cfg)
	if err != nil {
		return fmt.Errorf("failed to initialize worktree manager: %w", err)
	}

	// Discover worktrees
	fmt.Println("🔍 Discovering Git worktrees...")
	worktrees, err := worktreeManager.Discover()
	if err != nil {
		return fmt.Errorf("failed to discover worktrees: %w", err)
	}

	if len(worktrees) == 0 {
		fmt.Println("⚠️  No valid worktrees found")
		return nil
	}

	fmt.Printf("✓ Found %d valid worktrees\n", len(worktrees))

	if runDryRun {
		fmt.Println("\n🔍 Dry run - would execute on:")
		for _, wt := range worktrees {
			fmt.Printf("  - %s (%s)\n", wt.Name, wt.Path)
		}
		fmt.Printf("\nPrompt: %s\n", prompt.Name)
		fmt.Printf("Jobs: %d\n", cfg.Defaults.Jobs)
		fmt.Printf("Timeout: %s\n", cfg.Defaults.Timeout)
		fmt.Printf("Terminal: %t\n", runTerm)
		return nil
	}

	// Initialize executor
	exec, err := executor.NewPool(cfg)
	if err != nil {
		return fmt.Errorf("failed to initialize executor: %w", err)
	}

	// Execute jobs
	fmt.Printf("\n🚀 Executing '%s' across %d worktrees...\n", prompt.Name, len(worktrees))
	results, err := exec.Execute(prompt, worktrees, &executor.ExecuteOptions{
		Jobs:           cfg.Defaults.Jobs,
		Timeout:        runTimeout,
		UseTerm:        runTerm,
		TerminalOutput: runTerminalOutput,
		BaseBranch:     runBranch,
		Plan:           runPlan,
		Verbose:        viper.GetBool("verbose"),
	})
	if err != nil {
		return fmt.Errorf("execution failed: %w", err)
	}

	// Report results
	fmt.Printf("\n📊 Execution Summary\n")
	fmt.Printf("====================\n")
	fmt.Printf("Total Jobs: %d\n", len(results))

	successful := 0
	failed := 0
	for _, result := range results {
		if result.Status == "success" {
			successful++
		} else {
			failed++
		}
	}

	fmt.Printf("Successful: %d\n", successful)
	fmt.Printf("Failed: %d\n", failed)

	if failed > 0 {
		fmt.Printf("\nFailed Jobs:\n")
		for _, result := range results {
			if result.Status != "success" {
				fmt.Printf("- %s: %s\n", result.Worktree, result.ErrorMessage)
			}
		}
	}

	return nil
}