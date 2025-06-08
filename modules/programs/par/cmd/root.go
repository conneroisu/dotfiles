// Package cmd implements the CLI commands for par
package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var cfgFile string

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:   "par",
	Short: "Parallel Claude Code Runner",
	Long: `Par is a CLI tool that runs Claude Code across multiple Git worktrees simultaneously,
applying the same initial prompt to achieve consistent goals across different codebases or branches.

Use cases:
- Multi-branch development: Apply code changes across multiple feature branches
- Planned development: Plan prior to changes with the --plan flag
- Smart branching: Use the -b/--branch flag to branch from a specific base
- Terminal integration: Use --terms to open each job in separate terminal windows`,
	Version: "0.1.0",
}

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() error {
	return rootCmd.Execute()
}

func init() {
	cobra.OnInitialize(initConfig)

	// Global flags
	rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.config/par/config.yaml)")
	rootCmd.PersistentFlags().Bool("debug", false, "enable debug logging")
	rootCmd.PersistentFlags().Bool("verbose", false, "enable verbose output")
}

// initConfig reads in config file and ENV variables if set.
func initConfig() {
	if cfgFile != "" {
		// Use config file from the flag.
		viper.SetConfigFile(cfgFile)
	} else {
		// Find home directory.
		home, err := os.UserHomeDir()
		cobra.CheckErr(err)

		// Search config in home/.config/par directory with name "config" (without extension).
		viper.AddConfigPath(home + "/.config/par")
		viper.SetConfigType("yaml")
		viper.SetConfigName("config")
	}

	viper.AutomaticEnv() // read in environment variables that match

	// If a config file is found, read it in.
	if err := viper.ReadInConfig(); err == nil {
		if viper.GetBool("verbose") {
			fmt.Fprintln(os.Stderr, "Using config file:", viper.ConfigFileUsed())
		}
	}
}