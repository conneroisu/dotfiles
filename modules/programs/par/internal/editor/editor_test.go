package editor

import (
	"bytes"
	"errors"
	"strings"
	"testing"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/interfaces"
)

func TestLauncher_LaunchEditor_Success(t *testing.T) {
	// Setup mocks
	mockFS := interfaces.NewMockFileSystem()
	mockCmd := interfaces.NewMockCommandExecutor()
	mockEnv := interfaces.NewMockEnvironment()
	mockProc := &interfaces.MockMarkdownProcessor{
		Template: "# Test Template",
		Content:  "Test content extracted",
	}

	// Set editor environment variable
	mockEnv.Setenv("EDITOR", "vim")

	launcher := NewLauncher(mockFS, mockCmd, mockEnv, mockProc)

	// Test successful launch
	content, err := launcher.LaunchEditor("test-prompt", false)

	if err != nil {
		t.Fatalf("Expected no error, got: %v", err)
	}

	if content != "Test content extracted" {
		t.Errorf("Expected 'Test content extracted', got: %s", content)
	}

	// Verify command was created correctly
	if len(mockCmd.Commands) != 1 {
		t.Fatalf("Expected 1 command, got: %d", len(mockCmd.Commands))
	}

	cmd := mockCmd.Commands[0]
	if cmd.Name != "vim" {
		t.Errorf("Expected command name 'vim', got: %s", cmd.Name)
	}
}

func TestLauncher_LaunchEditor_DefaultEditor(t *testing.T) {
	// Setup mocks with no EDITOR set
	mockFS := interfaces.NewMockFileSystem()
	mockCmd := interfaces.NewMockCommandExecutor()
	mockEnv := interfaces.NewMockEnvironment()
	mockProc := &interfaces.MockMarkdownProcessor{
		Template: "# Test Template",
		Content:  "Test content",
	}

	launcher := NewLauncher(mockFS, mockCmd, mockEnv, mockProc)

	_, err := launcher.LaunchEditor("test", false)

	if err != nil {
		t.Fatalf("Expected no error, got: %v", err)
	}

	// Verify default editor (vim) was used
	if len(mockCmd.Commands) != 1 {
		t.Fatalf("Expected 1 command, got: %d", len(mockCmd.Commands))
	}

	cmd := mockCmd.Commands[0]
	if cmd.Name != "vim" {
		t.Errorf("Expected default editor 'vim', got: %s", cmd.Name)
	}
}

func TestLauncher_LaunchEditor_CreateTempError(t *testing.T) {
	// Setup mocks with CreateTemp error
	mockFS := interfaces.NewMockFileSystem()
	mockFS.CreateTempFn = func(dir, pattern string) (interfaces.File, error) {
		return nil, errors.New("temp file creation failed")
	}

	mockCmd := interfaces.NewMockCommandExecutor()
	mockEnv := interfaces.NewMockEnvironment()
	mockProc := &interfaces.MockMarkdownProcessor{}

	launcher := NewLauncher(mockFS, mockCmd, mockEnv, mockProc)

	_, err := launcher.LaunchEditor("test", false)

	if err == nil {
		t.Fatal("Expected error for CreateTemp failure")
	}

	if !strings.Contains(err.Error(), "failed to create temporary file") {
		t.Errorf("Expected 'failed to create temporary file' in error, got: %v", err)
	}
}

func TestLauncher_LaunchEditor_WriteError(t *testing.T) {
	// Setup mocks with write error
	mockFS := interfaces.NewMockFileSystem()
	mockFile := &interfaces.MockFile{
		NameValue: "/tmp/test.md",
		WriteErr:  errors.New("write failed"),
	}
	mockFS.CreateTempFn = func(dir, pattern string) (interfaces.File, error) {
		return mockFile, nil
	}

	mockCmd := interfaces.NewMockCommandExecutor()
	mockEnv := interfaces.NewMockEnvironment()
	mockProc := &interfaces.MockMarkdownProcessor{
		Template: "# Test Template",
	}

	launcher := NewLauncher(mockFS, mockCmd, mockEnv, mockProc)

	_, err := launcher.LaunchEditor("test", false)

	if err == nil {
		t.Fatal("Expected error for write failure")
	}

	if !strings.Contains(err.Error(), "failed to write template to file") {
		t.Errorf("Expected 'failed to write template to file' in error, got: %v", err)
	}
}

func TestLauncher_LaunchEditor_CommandError(t *testing.T) {
	// Setup mocks with command execution error
	mockFS := interfaces.NewMockFileSystem()
	mockCmd := interfaces.NewMockCommandExecutor()
	mockCmd.CommandFunc = func(name string, arg ...string) interfaces.Command {
		return &interfaces.MockCommand{
			Name:   name,
			Args:   arg,
			RunErr: errors.New("editor failed"),
		}
	}

	mockEnv := interfaces.NewMockEnvironment()
	mockProc := &interfaces.MockMarkdownProcessor{
		Template: "# Test Template",
	}

	launcher := NewLauncher(mockFS, mockCmd, mockEnv, mockProc)

	_, err := launcher.LaunchEditor("test", false)

	if err == nil {
		t.Fatal("Expected error for command failure")
	}

	if !strings.Contains(err.Error(), "editor command failed") {
		t.Errorf("Expected 'editor command failed' in error, got: %v", err)
	}
}

func TestLauncher_LaunchEditor_ReadError(t *testing.T) {
	// Setup mocks with read error
	mockFS := interfaces.NewMockFileSystem()
	mockFS.ReadFileFn = func(filename string) ([]byte, error) {
		return nil, errors.New("read failed")
	}

	mockCmd := interfaces.NewMockCommandExecutor()
	mockEnv := interfaces.NewMockEnvironment()
	mockProc := &interfaces.MockMarkdownProcessor{
		Template: "# Test Template",
	}

	launcher := NewLauncher(mockFS, mockCmd, mockEnv, mockProc)

	_, err := launcher.LaunchEditor("test", false)

	if err == nil {
		t.Fatal("Expected error for read failure")
	}

	if !strings.Contains(err.Error(), "failed to read edited content") {
		t.Errorf("Expected 'failed to read edited content' in error, got: %v", err)
	}
}

func TestLauncher_LaunchEditor_FileNameSanitization(t *testing.T) {
	// Setup mocks
	mockFS := interfaces.NewMockFileSystem()
	var createdFileName string

	// Override CreateTemp to capture the filename pattern
	mockFS.CreateTempFn = func(dir, pattern string) (interfaces.File, error) {
		// Simulate the filename that would be created
		createdFileName = strings.ReplaceAll(pattern, "*", "123")
		file := &interfaces.MockFile{
			NameValue: dir + "/" + createdFileName,
			Content:   &bytes.Buffer{},
		}
		// Also set up ReadFile to return content for this file
		mockFS.Files[file.NameValue] = []byte("Test content")
		return file, nil
	}

	mockCmd := interfaces.NewMockCommandExecutor()
	mockEnv := interfaces.NewMockEnvironment()
	mockProc := &interfaces.MockMarkdownProcessor{
		Template: "# Test Template",
		Content:  "Test content",
	}

	launcher := NewLauncher(mockFS, mockCmd, mockEnv, mockProc)

	// Test with special characters in prompt name
	_, err := launcher.LaunchEditor("test prompt/with spaces", false)

	if err != nil {
		t.Fatalf("Expected no error, got: %v", err)
	}

	// Verify temp file was created with sanitized name
	expectedPattern := "par-prompt-test-prompt-with-spaces"
	if !strings.Contains(createdFileName, expectedPattern) {
		t.Errorf("Expected filename to contain '%s', got: %s", expectedPattern, createdFileName)
	}
}

func TestMarkdownProcessor_GenerateTemplate_Regular(t *testing.T) {
	processor := NewMarkdownProcessor()

	template := processor.GenerateTemplate("test-prompt", false)

	// Verify template contains expected elements
	if !strings.Contains(template, "<!-- Par Prompt Creation -->") {
		t.Error("Template should contain creation comment")
	}

	if !strings.Contains(template, "<!-- Prompt Name: test-prompt -->") {
		t.Error("Template should contain prompt name")
	}

	if !strings.Contains(template, "# Prompt Content") {
		t.Error("Template should contain prompt content header")
	}

	if !strings.Contains(template, "## Your Prompt") {
		t.Error("Template should contain your prompt section")
	}

	// Should NOT contain template-specific content
	if strings.Contains(template, "{{.VariableName}}") {
		t.Error("Regular template should not contain template variable examples")
	}
}

func TestMarkdownProcessor_GenerateTemplate_TemplateMode(t *testing.T) {
	processor := NewMarkdownProcessor()

	template := processor.GenerateTemplate("test-template", true)

	// Verify template contains template-specific elements
	if !strings.Contains(template, "<!-- Template Mode: Variables can be used") {
		t.Error("Template mode should contain template instructions")
	}

	if !strings.Contains(template, "{{.FunctionName}}") {
		t.Error("Template mode should contain variable examples")
	}

	if !strings.Contains(template, "Go template syntax") {
		t.Error("Template mode should mention Go template syntax")
	}
}

func TestMarkdownProcessor_ExtractContent_StructuredContent(t *testing.T) {
	processor := NewMarkdownProcessor()

	markdown := `<!-- Par Prompt Creation -->
<!-- Some comments -->

# Prompt Content

Some intro text

## Your Prompt

<!-- Write your actual prompt content below -->

This is the actual prompt content
that should be extracted.

More content here.`

	content := processor.ExtractContent(markdown)

	expected := "This is the actual prompt content\nthat should be extracted.\n\nMore content here."
	if content != expected {
		t.Errorf("Expected:\n%s\n\nGot:\n%s", expected, content)
	}
}

func TestMarkdownProcessor_ExtractContent_FallbackMode(t *testing.T) {
	processor := NewMarkdownProcessor()

	markdown := `<!-- Some comment -->
This is just plain content
without structure.
<!-- Another comment -->`

	content := processor.ExtractContent(markdown)

	expected := "This is just plain content\nwithout structure."
	if content != expected {
		t.Errorf("Expected:\n%s\n\nGot:\n%s", expected, content)
	}
}

func TestMarkdownProcessor_ExtractContent_EmptyContent(t *testing.T) {
	processor := NewMarkdownProcessor()

	markdown := `<!-- Par Prompt Creation -->
<!-- Comments only -->

## Your Prompt

<!-- Write your actual prompt content below -->`

	content := processor.ExtractContent(markdown)

	if strings.TrimSpace(content) != "" {
		t.Errorf("Expected empty content, got: '%s'", content)
	}
}
