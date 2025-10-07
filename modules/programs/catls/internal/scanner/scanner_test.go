package scanner

import (
	"path/filepath"
	"testing"
)

func TestGetRelativePath(t *testing.T) {
	s := New()

	tests := []struct {
		name       string
		fullPath   string
		directory  string
		relativeTo string
		want       string
		wantErr    bool
	}{
		{
			name:       "relative to directory when RelativeTo is empty",
			fullPath:   "/home/user/project/src/main.go",
			directory:  "/home/user/project",
			relativeTo: "",
			want:       "src/main.go",
			wantErr:    false,
		},
		{
			name:       "relative to current directory when directory is dot",
			fullPath:   "src/main.go",
			directory:  ".",
			relativeTo: "",
			want:       "src/main.go",
			wantErr:    false,
		},
		{
			name:       "relative to RelativeTo when set",
			fullPath:   "/home/user/project/src/main.go",
			directory:  "/home/user/project/src",
			relativeTo: "/home/user",
			want:       "project/src/main.go",
			wantErr:    false,
		},
		{
			name:       "relative to dot RelativeTo",
			fullPath:   "/home/user/project/src/main.go",
			directory:  "/home/user/project",
			relativeTo: ".",
			want:       "/home/user/project/src/main.go",
			wantErr:    false,
		},
		{
			name:       "same directory",
			fullPath:   "/home/user/project/main.go",
			directory:  "/home/user/project",
			relativeTo: "/home/user/project",
			want:       "main.go",
			wantErr:    false,
		},
		{
			name:       "parent directory RelativeTo",
			fullPath:   "/home/user/project/src/lib/utils.go",
			directory:  "/home/user/project/src",
			relativeTo: "/home/user/project",
			want:       "src/lib/utils.go",
			wantErr:    false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			cfg := Config{
				Directory:  tt.directory,
				RelativeTo: tt.relativeTo,
			}

			got, err := s.getRelativePath(tt.fullPath, cfg)
			if (err != nil) != tt.wantErr {
				t.Errorf("getRelativePath() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if got != tt.want {
				t.Errorf("getRelativePath() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestGetRelativePathWithTempDir(t *testing.T) {
	s := New()

	t.Run("relative path in temp directory", func(t *testing.T) {
		tmpDir := t.TempDir()

		subDir := filepath.Join(tmpDir, "subdir")
		filePath := filepath.Join(subDir, "test.txt")

		cfg := Config{
			Directory:  subDir,
			RelativeTo: "",
		}

		got, err := s.getRelativePath(filePath, cfg)
		if err != nil {
			t.Fatalf("getRelativePath() unexpected error: %v", err)
		}

		want := "test.txt"
		if got != want {
			t.Errorf("getRelativePath() = %v, want %v", got, want)
		}
	})

	t.Run("relative to parent temp directory", func(t *testing.T) {
		tmpDir := t.TempDir()

		subDir := filepath.Join(tmpDir, "subdir")
		filePath := filepath.Join(subDir, "test.txt")

		cfg := Config{
			Directory:  subDir,
			RelativeTo: tmpDir,
		}

		got, err := s.getRelativePath(filePath, cfg)
		if err != nil {
			t.Fatalf("getRelativePath() unexpected error: %v", err)
		}

		want := filepath.Join("subdir", "test.txt")
		if got != want {
			t.Errorf("getRelativePath() = %v, want %v", got, want)
		}
	})

	t.Run("relative to different temp directory", func(t *testing.T) {
		tmpDir1 := t.TempDir()
		tmpDir2 := t.TempDir()

		filePath := filepath.Join(tmpDir1, "test.txt")

		cfg := Config{
			Directory:  tmpDir1,
			RelativeTo: tmpDir2,
		}

		got, err := s.getRelativePath(filePath, cfg)
		if err != nil {
			t.Fatalf("getRelativePath() unexpected error: %v", err)
		}

		// Should contain .. to navigate between temp directories
		if !filepath.IsAbs(got) && len(got) > 0 {
			// Result should be a relative path
			if got == "test.txt" {
				t.Errorf("getRelativePath() = %v, should contain path traversal", got)
			}
		}
	})
}
