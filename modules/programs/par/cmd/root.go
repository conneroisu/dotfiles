package cmd

import (
	"context"

	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "par",
	Short: "Parallel Claude Code Runner",
	Long: `Par is a Go program that runs the Claude Code CLI across multiple Git worktree 
branches/directories simultaneously, applying the same initial prompt to achieve 
consistent goals across different codebases or branches.`,
	Version: "0.1.0",
}

func Execute() error {
	return rootCmd.Execute()
}

func ExecuteContext(ctx context.Context) error {
	return rootCmd.ExecuteContext(ctx)
}

func init() {
	rootCmd.AddCommand(addCmd)
	rootCmd.AddCommand(runCmd)
	rootCmd.AddCommand(listCmd)
	rootCmd.AddCommand(cleanCmd)
}
