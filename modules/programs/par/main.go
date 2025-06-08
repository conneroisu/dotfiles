// Package main provides the Par CLI - Parallel Claude Code Runner
package main

import (
	"fmt"
	"os"

	"github.com/conneroisu/dotfiles/modules/programs/par/cmd"
)

func main() {
	if err := cmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}
