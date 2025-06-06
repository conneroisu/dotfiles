package main

import (
	"os"

	"github.com/conneroisu/dotfiles/modules/programs/par/cmd"
)

func main() {
	if err := cmd.Execute(); err != nil {
		os.Exit(1)
	}
}
