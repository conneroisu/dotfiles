package interfaces

import (
	"bytes"
	"io"
	"os"
	"path/filepath"
	"strings"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/worktree"
)

// MockFileSystem implements FileSystem for testing
type MockFileSystem struct {
	Files        map[string][]byte
	FileInfos    map[string]os.FileInfo
	TempFiles    map[string]*MockFile
	CreateTempFn func(dir, pattern string) (File, error)
	ReadFileFn   func(filename string) ([]byte, error)
	RemoveFn     func(name string) error
	StatFn       func(name string) (os.FileInfo, error)
	TempDirValue string
}

func NewMockFileSystem() *MockFileSystem {
	return &MockFileSystem{
		Files:        make(map[string][]byte),
		FileInfos:    make(map[string]os.FileInfo),
		TempFiles:    make(map[string]*MockFile),
		TempDirValue: "/tmp",
	}
}

func (fs *MockFileSystem) CreateTemp(dir, pattern string) (File, error) {
	if fs.CreateTempFn != nil {
		return fs.CreateTempFn(dir, pattern)
	}

	// Generate a mock filename
	filename := filepath.Join(dir, strings.ReplaceAll(pattern, "*", "123"))
	file := &MockFile{
		NameValue: filename,
		Content:   &bytes.Buffer{},
	}
	fs.TempFiles[filename] = file
	return file, nil
}

func (fs *MockFileSystem) ReadFile(filename string) ([]byte, error) {
	if fs.ReadFileFn != nil {
		return fs.ReadFileFn(filename)
	}
	if content, exists := fs.Files[filename]; exists {
		return content, nil
	}
	if file, exists := fs.TempFiles[filename]; exists {
		return file.Content.Bytes(), nil
	}
	return nil, os.ErrNotExist
}

func (fs *MockFileSystem) WriteFile(filename string, data []byte, perm os.FileMode) error {
	fs.Files[filename] = data
	return nil
}

func (fs *MockFileSystem) Remove(name string) error {
	if fs.RemoveFn != nil {
		return fs.RemoveFn(name)
	}
	delete(fs.Files, name)
	delete(fs.TempFiles, name)
	return nil
}

func (fs *MockFileSystem) Stat(name string) (os.FileInfo, error) {
	if fs.StatFn != nil {
		return fs.StatFn(name)
	}
	if info, exists := fs.FileInfos[name]; exists {
		return info, nil
	}
	return nil, os.ErrNotExist
}

func (fs *MockFileSystem) TempDir() string {
	return fs.TempDirValue
}

// MockFile implements File for testing
type MockFile struct {
	NameValue string
	Content   *bytes.Buffer
	Closed    bool
	WriteErr  error
	CloseErr  error
}

func (f *MockFile) Write(p []byte) (n int, err error) {
	if f.WriteErr != nil {
		return 0, f.WriteErr
	}
	return f.Content.Write(p)
}

func (f *MockFile) WriteString(s string) (int, error) {
	if f.WriteErr != nil {
		return 0, f.WriteErr
	}
	return f.Content.WriteString(s)
}

func (f *MockFile) Close() error {
	f.Closed = true
	return f.CloseErr
}

func (f *MockFile) Name() string {
	return f.NameValue
}

// MockCommandExecutor implements CommandExecutor for testing
type MockCommandExecutor struct {
	Commands    []*MockCommand
	CommandFunc func(name string, arg ...string) Command
}

func NewMockCommandExecutor() *MockCommandExecutor {
	return &MockCommandExecutor{
		Commands: make([]*MockCommand, 0),
	}
}

func (ce *MockCommandExecutor) Command(name string, arg ...string) Command {
	if ce.CommandFunc != nil {
		return ce.CommandFunc(name, arg...)
	}

	cmd := &MockCommand{
		Name: name,
		Args: arg,
	}
	ce.Commands = append(ce.Commands, cmd)
	return cmd
}

// MockCommand implements Command for testing
type MockCommand struct {
	Name    string
	Args    []string
	RunErr  error
	StdinR  io.Reader
	StdoutW io.Writer
	StderrW io.Writer
	DirVal  string
	RunFunc func() error
}

func (c *MockCommand) Run() error {
	if c.RunFunc != nil {
		return c.RunFunc()
	}
	return c.RunErr
}

func (c *MockCommand) SetStdin(stdin io.Reader) {
	c.StdinR = stdin
}

func (c *MockCommand) SetStdout(stdout io.Writer) {
	c.StdoutW = stdout
}

func (c *MockCommand) SetStderr(stderr io.Writer) {
	c.StderrW = stderr
}

func (c *MockCommand) SetDir(dir string) {
	c.DirVal = dir
}

// MockEnvironment implements Environment for testing
type MockEnvironment struct {
	Vars map[string]string
}

func NewMockEnvironment() *MockEnvironment {
	return &MockEnvironment{
		Vars: make(map[string]string),
	}
}

func (e *MockEnvironment) Getenv(key string) string {
	return e.Vars[key]
}

func (e *MockEnvironment) Setenv(key, value string) error {
	e.Vars[key] = value
	return nil
}

// MockEditorLauncher implements EditorLauncher for testing
type MockEditorLauncher struct {
	LaunchFunc func(promptName string, isTemplate bool) (string, error)
	Content    string
	Error      error
}

func (el *MockEditorLauncher) LaunchEditor(promptName string, isTemplate bool) (string, error) {
	if el.LaunchFunc != nil {
		return el.LaunchFunc(promptName, isTemplate)
	}
	return el.Content, el.Error
}

// MockMarkdownProcessor implements MarkdownProcessor for testing
type MockMarkdownProcessor struct {
	GenerateFunc func(promptName string, isTemplate bool) string
	ExtractFunc  func(markdown string) string
	Template     string
	Content      string
}

func (mp *MockMarkdownProcessor) GenerateTemplate(promptName string, isTemplate bool) string {
	if mp.GenerateFunc != nil {
		return mp.GenerateFunc(promptName, isTemplate)
	}
	return mp.Template
}

func (mp *MockMarkdownProcessor) ExtractContent(markdown string) string {
	if mp.ExtractFunc != nil {
		return mp.ExtractFunc(markdown)
	}
	return mp.Content
}

// MockWorktreeFilter implements WorktreeFilter for testing
type MockWorktreeFilter struct {
	FilterFunc        func(worktrees []*worktree.Worktree) []*worktree.Worktree
	IsActualFunc      func(wt *worktree.Worktree) bool
	FilteredWorktrees []*worktree.Worktree
	IsActualResult    bool
}

func (wf *MockWorktreeFilter) FilterActualWorktrees(worktrees []*worktree.Worktree) []*worktree.Worktree {
	if wf.FilterFunc != nil {
		return wf.FilterFunc(worktrees)
	}
	return wf.FilteredWorktrees
}

func (wf *MockWorktreeFilter) IsActualWorktree(wt *worktree.Worktree) bool {
	if wf.IsActualFunc != nil {
		return wf.IsActualFunc(wt)
	}
	return wf.IsActualResult
}

// MockPromptValidator implements PromptValidator for testing
type MockPromptValidator struct {
	ValidateContentFunc func(content string) error
	ValidateNameFunc    func(name string) error
	ContentError        error
	NameError           error
}

func (pv *MockPromptValidator) ValidatePromptContent(content string) error {
	if pv.ValidateContentFunc != nil {
		return pv.ValidateContentFunc(content)
	}
	return pv.ContentError
}

func (pv *MockPromptValidator) ValidatePromptName(name string) error {
	if pv.ValidateNameFunc != nil {
		return pv.ValidateNameFunc(name)
	}
	return pv.NameError
}
