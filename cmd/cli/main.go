package main

import "github.com/alecthomas/kong"

// CLI is the root command for the CLI.
var CLI struct {
	System SystemCmd `cmd:"" help:"system commands (\"./systems\")"`

	Home HomeCmd `cmd:"" help:"home commands (\"./homes\")"`
}

func main() {
	ctx := kong.Parse(&CLI,
		kong.Name("cli"),
		kong.Description("A CLI for managing my dotfiles"),
		kong.UsageOnError(),
		kong.ConfigureHelp(kong.HelpOptions{
			Compact: true,
			Summary: true,
		}),
	)
	err := ctx.Run()
	ctx.FatalIfErrorf(err)
}
