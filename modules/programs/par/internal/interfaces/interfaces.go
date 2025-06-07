package interfaces

import (
	"io"
	"os"
	"time"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/worktree"
)

// FileSystem abstracts file system operations for testing
type FileSystem interface {
	CreateTemp(dir, pattern string) (File, error)
	ReadFile(filename string) ([]byte, error)
	WriteFile(filename string, data []byte, perm os.FileMode) error
	Remove(name string) error
	Stat(name string) (os.FileInfo, error)
	TempDir() string
}

// File abstracts file operations for testing
type File interface {
	io.Writer
	io.Closer
	Name() string
	WriteString(s string) (int, error)
}

// CommandExecutor abstracts command execution for testing
type CommandExecutor interface {
	Command(name string, arg ...string) Command
}

// Command abstracts exec.Cmd for testing
type Command interface {
	Run() error
	SetStdin(stdin io.Reader)
	SetStdout(stdout io.Writer)
	SetStderr(stderr io.Writer)
	SetDir(dir string)
}

// Environment abstracts environment variable access for testing
type Environment interface {
	Getenv(key string) string
	Setenv(key, value string) error
}

// EditorLauncher abstracts the editor launching functionality
type EditorLauncher interface {
	LaunchEditor(promptName string, isTemplate bool) (string, error)
}

// MarkdownProcessor abstracts markdown template generation and content extraction
type MarkdownProcessor interface {
	GenerateTemplate(promptName string, isTemplate bool) string
	ExtractContent(markdown string) string
}

// WorktreeFilter abstracts worktree filtering logic
type WorktreeFilter interface {
	FilterActualWorktrees(worktrees []*worktree.Worktree) []*worktree.Worktree
	IsActualWorktree(wt *worktree.Worktree) bool
}

// PromptValidator abstracts prompt validation logic
type PromptValidator interface {
	ValidatePromptContent(content string) error
	ValidatePromptName(name string) error
}

// TestableFileInfo implements os.FileInfo for testing
type TestableFileInfo struct {
	name    string
	size    int64
	mode    os.FileMode
	modTime time.Time
	isDir   bool
}

func (fi TestableFileInfo) Name() string       { return fi.name }
func (fi TestableFileInfo) Size() int64        { return fi.size }
func (fi TestableFileInfo) Mode() os.FileMode  { return fi.mode }
func (fi TestableFileInfo) ModTime() time.Time { return fi.modTime }
func (fi TestableFileInfo) IsDir() bool        { return fi.isDir }
func (fi TestableFileInfo) Sys() interface{}   { return nil }

// NewTestableFileInfo creates a TestableFileInfo for testing
func NewTestableFileInfo(name string, size int64, mode os.FileMode, isDir bool) TestableFileInfo {
	return TestableFileInfo{
		name:    name,
		size:    size,
		mode:    mode,
		modTime: time.Now(),
		isDir:   isDir,
	}
}
