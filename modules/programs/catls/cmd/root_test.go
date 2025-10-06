package cmd

import (
	"testing"

	"github.com/spf13/cobra"
	"github.com/spf13/pflag"
)

// createTestFlags creates a fresh set of flags for testing
func createTestFlags() *pflag.FlagSet {
	flags := pflag.NewFlagSet("test", pflag.ContinueOnError)

	flags.BoolP("all", "a", false, "Include hidden files")
	flags.BoolP("recursive", "r", false, "Recursively list files in subdirectories")
	flags.StringSlice("ignore-dir", defaultIgnoreDirs(), "Ignore directory DIR")
	flags.StringSlice("globs", nil, "Only include files matching glob pattern")
	flags.StringSlice("ignore-globs", nil, "Ignore files matching glob pattern")
	flags.String("pattern", "", "Only show lines matching glob PATTERN")
	flags.BoolP("line-numbers", "n", false, "Show line numbers")
	flags.Bool("debug", false, "Enable debug output")
	flags.Bool("omit-bins", false, "Skip binary files in output")
	flags.StringP("format", "f", "xml", "Output format: xml, json, markdown")
	flags.String("relative-to", "", "Display paths relative to this directory")

	return flags
}

func TestBuildConfig_RelativeToFlag(t *testing.T) {
	tests := []struct {
		name           string
		args           []string
		flags          map[string]string
		wantRelativeTo string
		wantDirectory  string
	}{
		{
			name:           "no relative-to flag uses default",
			args:           []string{},
			flags:          map[string]string{},
			wantRelativeTo: "",
			wantDirectory:  ".",
		},
		{
			name:           "relative-to flag set to current directory",
			args:           []string{},
			flags:          map[string]string{"relative-to": "."},
			wantRelativeTo: ".",
			wantDirectory:  ".",
		},
		{
			name:           "relative-to flag set to absolute path",
			args:           []string{},
			flags:          map[string]string{"relative-to": "/home/user"},
			wantRelativeTo: "/home/user",
			wantDirectory:  ".",
		},
		{
			name:           "relative-to with directory arg",
			args:           []string{"/some/path"},
			flags:          map[string]string{"relative-to": "/home/user"},
			wantRelativeTo: "/home/user",
			wantDirectory:  "/some/path",
		},
		{
			name:           "relative-to with relative path",
			args:           []string{"./src"},
			flags:          map[string]string{"relative-to": "./"},
			wantRelativeTo: "./",
			wantDirectory:  "./src",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create a new command with fresh flags for each test
			cmd := &cobra.Command{
				Use: "test",
			}
			cmd.Flags().AddFlagSet(createTestFlags())

			// Set flags
			for name, value := range tt.flags {
				if err := cmd.Flags().Set(name, value); err != nil {
					t.Fatalf("failed to set flag %s: %v", name, err)
				}
			}

			cfg, err := buildConfig(cmd, tt.args)
			if err != nil {
				t.Fatalf("buildConfig() unexpected error: %v", err)
			}

			if cfg.RelativeTo != tt.wantRelativeTo {
				t.Errorf("buildConfig().RelativeTo = %v, want %v", cfg.RelativeTo, tt.wantRelativeTo)
			}

			if cfg.Directory != tt.wantDirectory {
				t.Errorf("buildConfig().Directory = %v, want %v", cfg.Directory, tt.wantDirectory)
			}
		})
	}
}

func TestBuildConfig_RelativeToWithOtherFlags(t *testing.T) {
	cmd := &cobra.Command{
		Use: "test",
	}
	cmd.Flags().AddFlagSet(createTestFlags())

	// Set multiple flags
	flags := map[string]string{
		"relative-to": "/home/user/project",
		"format":      "json",
		"recursive":   "true",
	}

	for name, value := range flags {
		if err := cmd.Flags().Set(name, value); err != nil {
			t.Fatalf("failed to set flag %s: %v", name, err)
		}
	}

	cfg, err := buildConfig(cmd, []string{"./src"})
	if err != nil {
		t.Fatalf("buildConfig() unexpected error: %v", err)
	}

	if cfg.RelativeTo != "/home/user/project" {
		t.Errorf("RelativeTo = %v, want /home/user/project", cfg.RelativeTo)
	}

	if cfg.Directory != "./src" {
		t.Errorf("Directory = %v, want ./src", cfg.Directory)
	}

	if !cfg.Recursive {
		t.Errorf("Recursive = false, want true")
	}

	if string(cfg.OutputFormat) != "json" {
		t.Errorf("OutputFormat = %v, want json", cfg.OutputFormat)
	}
}
