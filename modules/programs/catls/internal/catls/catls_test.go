package catls

import (
	"bytes"
	"context"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestRelativeToIntegration(t *testing.T) {
	tests := []struct {
		name           string
		setupFiles     map[string]string // path -> content
		directory      string            // scan directory
		relativeTo     string            // RelativeTo path
		wantPathPrefix string            // expected path prefix in output
	}{
		{
			name: "no RelativeTo uses scan directory",
			setupFiles: map[string]string{
				"test.txt": "hello",
			},
			directory:      "",
			relativeTo:     "",
			wantPathPrefix: "test.txt",
		},
		{
			name: "RelativeTo parent directory",
			setupFiles: map[string]string{
				"subdir/test.txt": "hello",
			},
			directory:      "subdir",
			relativeTo:     "", // will be set to tmpDir
			wantPathPrefix: "subdir/test.txt",
		},
		{
			name: "RelativeTo current directory",
			setupFiles: map[string]string{
				"test.txt": "hello",
			},
			directory:      "",
			relativeTo:     ".",
			wantPathPrefix: "test.txt",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Create temp directory
			tmpDir := t.TempDir()

			// Create test files
			for path, content := range tt.setupFiles {
				fullPath := filepath.Join(tmpDir, path)
				dir := filepath.Dir(fullPath)

				if err := os.MkdirAll(dir, 0755); err != nil {
					t.Fatalf("failed to create directory %s: %v", dir, err)
				}

				if err := os.WriteFile(fullPath, []byte(content), 0644); err != nil {
					t.Fatalf("failed to write file %s: %v", fullPath, err)
				}
			}

			// Set up config
			scanDir := tmpDir
			if tt.directory != "" {
				scanDir = filepath.Join(tmpDir, tt.directory)
			}

			relTo := tt.relativeTo
			if tt.name == "RelativeTo parent directory" {
				relTo = tmpDir
			}

			cfg := &Config{
				Directory:    scanDir,
				Recursive:    true,
				RelativeTo:   relTo,
				OutputFormat: "xml",
			}

			// Capture output
			oldStdout := os.Stdout
			r, w, _ := os.Pipe()
			os.Stdout = w

			// Run the application
			app := New(cfg)
			err := app.Run(context.Background())

			// Restore stdout
			w.Close()
			os.Stdout = oldStdout

			if err != nil {
				t.Fatalf("Run() unexpected error: %v", err)
			}

			// Read output
			var buf bytes.Buffer
			io.Copy(&buf, r)
			output := buf.String()

			// Verify the path in output contains expected prefix
			if !strings.Contains(output, tt.wantPathPrefix) {
				t.Errorf("output does not contain expected path prefix %q\noutput:\n%s", tt.wantPathPrefix, output)
			}
		})
	}
}

func TestRelativeToWithNestedDirectories(t *testing.T) {
	tmpDir := t.TempDir()

	// Create nested directory structure
	files := map[string]string{
		"src/main.go":         "package main",
		"src/lib/utils.go":    "package lib",
		"tests/main_test.go":  "package main_test",
		"README.md":           "# Project",
	}

	for path, content := range files {
		fullPath := filepath.Join(tmpDir, path)
		dir := filepath.Dir(fullPath)

		if err := os.MkdirAll(dir, 0755); err != nil {
			t.Fatalf("failed to create directory %s: %v", dir, err)
		}

		if err := os.WriteFile(fullPath, []byte(content), 0644); err != nil {
			t.Fatalf("failed to write file %s: %v", fullPath, err)
		}
	}

	t.Run("scan src with relative-to project root", func(t *testing.T) {
		cfg := &Config{
			Directory:    filepath.Join(tmpDir, "src"),
			Recursive:    true,
			RelativeTo:   tmpDir,
			OutputFormat: "xml",
		}

		// Capture output
		oldStdout := os.Stdout
		r, w, _ := os.Pipe()
		os.Stdout = w

		app := New(cfg)
		err := app.Run(context.Background())

		w.Close()
		os.Stdout = oldStdout

		if err != nil {
			t.Fatalf("Run() unexpected error: %v", err)
		}

		var buf bytes.Buffer
		io.Copy(&buf, r)
		output := buf.String()

		// Should contain paths relative to project root
		expectedPaths := []string{
			"src/main.go",
			"src/lib/utils.go",
		}

		for _, path := range expectedPaths {
			if !strings.Contains(output, path) {
				t.Errorf("output should contain path %q\noutput:\n%s", path, output)
			}
		}

		// Should NOT contain just "main.go" or "lib/utils.go"
		if strings.Contains(output, `path="main.go"`) {
			t.Errorf("output should not contain bare 'main.go' when relative-to is set")
		}
	})

	t.Run("scan project with relative-to same as directory", func(t *testing.T) {
		cfg := &Config{
			Directory:    tmpDir,
			Recursive:    true,
			RelativeTo:   tmpDir,
			OutputFormat: "xml",
		}

		// Capture output
		oldStdout := os.Stdout
		r, w, _ := os.Pipe()
		os.Stdout = w

		app := New(cfg)
		err := app.Run(context.Background())

		w.Close()
		os.Stdout = oldStdout

		if err != nil {
			t.Fatalf("Run() unexpected error: %v", err)
		}

		var buf bytes.Buffer
		io.Copy(&buf, r)
		output := buf.String()

		// Paths should be relative to tmpDir
		expectedPaths := []string{
			"src/main.go",
			"README.md",
		}

		for _, path := range expectedPaths {
			if !strings.Contains(output, path) {
				t.Errorf("output should contain path %q\noutput:\n%s", path, output)
			}
		}
	})
}

func TestRelativeToWithDifferentOutputFormats(t *testing.T) {
	tmpDir := t.TempDir()

	// Create a test file
	testFile := filepath.Join(tmpDir, "test.txt")
	if err := os.WriteFile(testFile, []byte("test content"), 0644); err != nil {
		t.Fatalf("failed to write test file: %v", err)
	}

	formats := []OutputFormat{"xml", "json", "markdown"}

	for _, format := range formats {
		t.Run(string(format), func(t *testing.T) {
			cfg := &Config{
				Directory:    tmpDir,
				Recursive:    false,
				RelativeTo:   tmpDir,
				OutputFormat: format,
			}

			// Capture output
			oldStdout := os.Stdout
			r, w, _ := os.Pipe()
			os.Stdout = w

			app := New(cfg)
			err := app.Run(context.Background())

			w.Close()
			os.Stdout = oldStdout

			if err != nil {
				t.Fatalf("Run() unexpected error: %v", err)
			}

			var buf bytes.Buffer
			io.Copy(&buf, r)
			output := buf.String()

			// Should contain test.txt in output
			if !strings.Contains(output, "test.txt") {
				t.Errorf("output should contain 'test.txt'\noutput:\n%s", output)
			}

			// Verify format-specific output
			switch format {
			case "xml":
				if !strings.Contains(output, "<file") {
					t.Errorf("xml output should contain <file tag")
				}
			case "json":
				if !strings.Contains(output, "\"path\"") {
					t.Errorf("json output should contain path field")
				}
			case "markdown":
				if !strings.Contains(output, "##") || !strings.Contains(output, "```") {
					t.Errorf("markdown output should contain markdown formatting")
				}
			}
		})
	}
}
