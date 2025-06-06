package interfaces

import (
	"io"
	"os"
	"os/exec"
)

// RealFileSystem implements FileSystem using real OS calls
type RealFileSystem struct{}

func (fs *RealFileSystem) CreateTemp(dir, pattern string) (File, error) {
	file, err := os.CreateTemp(dir, pattern)
	if err != nil {
		return nil, err
	}
	return &RealFile{file}, nil
}

func (fs *RealFileSystem) ReadFile(filename string) ([]byte, error) {
	return os.ReadFile(filename)
}

func (fs *RealFileSystem) WriteFile(filename string, data []byte, perm os.FileMode) error {
	return os.WriteFile(filename, data, perm)
}

func (fs *RealFileSystem) Remove(name string) error {
	return os.Remove(name)
}

func (fs *RealFileSystem) Stat(name string) (os.FileInfo, error) {
	return os.Stat(name)
}

func (fs *RealFileSystem) TempDir() string {
	return os.TempDir()
}

// RealFile implements File wrapping os.File
type RealFile struct {
	*os.File
}

func (f *RealFile) WriteString(s string) (int, error) {
	return f.File.WriteString(s)
}

// RealCommandExecutor implements CommandExecutor using real exec calls
type RealCommandExecutor struct{}

func (ce *RealCommandExecutor) Command(name string, arg ...string) Command {
	cmd := exec.Command(name, arg...)
	return &RealCommand{cmd}
}

// RealCommand implements Command wrapping exec.Cmd
type RealCommand struct {
	*exec.Cmd
}

func (c *RealCommand) Run() error {
	return c.Cmd.Run()
}

func (c *RealCommand) SetStdin(stdin io.Reader) {
	c.Cmd.Stdin = stdin
}

func (c *RealCommand) SetStdout(stdout io.Writer) {
	c.Cmd.Stdout = stdout
}

func (c *RealCommand) SetStderr(stderr io.Writer) {
	c.Cmd.Stderr = stderr
}

func (c *RealCommand) SetDir(dir string) {
	c.Cmd.Dir = dir
}

// RealEnvironment implements Environment using real OS calls
type RealEnvironment struct{}

func (e *RealEnvironment) Getenv(key string) string {
	return os.Getenv(key)
}

func (e *RealEnvironment) Setenv(key, value string) error {
	return os.Setenv(key, value)
}
