package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/config"
)

var (
	cfgFile string
	verbose bool
)

var rootCmd = &cobra.Command{
	Use:   "par",
	Short: "Parallel Claude Code Runner",
	Long: `Par is a CLI tool that runs the Claude Code CLI across multiple Git worktree 
branches/directories simultaneously, applying the same initial prompt to achieve 
consistent goals across different codebases or branches.

Use cases:
- Multi-branch Development: Apply different code changes across multiple feature branches
- Planned Development: Plan prior to changes conditionally with the --plan flag
- Smart Branching: Use the -b/--branch flag to branch from a specific base branch
- Terminal Integration: Use the --terms flag to open each job in separate terminal windows`,
	PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
		return config.Init()
	},
}

func Execute() error {
	return rootCmd.Execute()
}

func init() {
	cobra.OnInitialize(initConfig)
	
	rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.config/par/config.yaml)")
	rootCmd.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "verbose output")
	
	rootCmd.AddCommand(addCmd)
	rootCmd.AddCommand(runCmd)
	rootCmd.AddCommand(listCmd)
	rootCmd.AddCommand(cleanCmd)
}

func initConfig() {
	if cfgFile != "" {
		fmt.Printf("Custom config file specified: %s\n", cfgFile)
	}
}