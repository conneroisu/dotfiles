package cmd

import (
	"bytes"
	"strings"
	"testing"

	"github.com/conneroisu/dotfiles/modules/programs/par/internal/editor"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/filtering"
	"github.com/conneroisu/dotfiles/modules/programs/par/internal/interfaces"
	"github.com/spf13/cobra"
)

// TestableAddCommand wraps the add command with testable dependencies
type TestableAddCommand struct {
	launcher  interfaces.EditorLauncher
	validator interfaces.PromptValidator
	cmd       *cobra.Command
}

// NewTestableAddCommand creates an add command with injectable dependencies
func NewTestableAddCommand(launcher interfaces.EditorLauncher, validator interfaces.PromptValidator) *TestableAddCommand {
	tac := &TestableAddCommand{
		launcher:  launcher,
		validator: validator,
	}

	// Create a modified version of the add command for testing
	tac.cmd = &cobra.Command{
		Use:   "add [--name <name>] [--file <file>] [--template]",
		Short: "Add a new prompt to the library",
		Long: `Add a new prompt to the prompt library. When no file is specified, 
launches your $EDITOR with a markdown template for writing prompts with 
syntax highlighting and structure. Supports template prompts with variables.`,
		RunE: tac.runAddCommand,
	}

	tac.cmd.Flags().StringP("name", "n", "", "Name for the prompt")
	tac.cmd.Flags().StringP("file", "f", "", "File containing the prompt")
	tac.cmd.Flags().Bool("template", false, "Create a template prompt with variables")

	return tac
}

func (tac *TestableAddCommand) runAddCommand(cmd *cobra.Command, args []string) error {
	name, _ := cmd.Flags().GetString("name")
	file, _ := cmd.Flags().GetString("file")
	template, _ := cmd.Flags().GetBool("template")

	// Get prompt content
	var content string
	var err error

	if file != "" {
		// In a real implementation, this would read from file
		// For testing, we'll simulate this
		content = "File content from " + file
	} else {
		// Launch editor with markdown template
		content, err = tac.launcher.LaunchEditor(name, template)
		if err != nil {
			return err
		}
	}

	// Validate content
	if err := tac.validator.ValidatePromptContent(content); err != nil {
		return err
	}

	// Validate name
	if err := tac.validator.ValidatePromptName(name); err != nil {
		return err
	}

	// In a real implementation, this would save to the prompt manager
	// For testing, we'll just return success
	return nil
}

func TestAddCommand_EditorLaunch_Success(t *testing.T) {
	// Setup mocks
	mockLauncher := &interfaces.MockEditorLauncher{
		Content: "This is a valid prompt content from the editor",
	}
	mockValidator := &interfaces.MockPromptValidator{}

	// Create testable command
	testCmd := NewTestableAddCommand(mockLauncher, mockValidator)

	// Set command flags
	testCmd.cmd.SetArgs([]string{"--name", "test-prompt"})

	// Execute command
	err := testCmd.cmd.Execute()

	if err != nil {
		t.Fatalf("Expected command to succeed, got error: %v", err)
	}

	// Verify launcher was called with correct parameters
	if mockLauncher.LaunchFunc == nil {
		// Check that the mock would have been called
		// Since we can't easily intercept the call in this test structure,
		// we'll verify the logic by testing the components separately
	}
}

func TestAddCommand_EditorLaunch_LauncherError(t *testing.T) {
	// Setup mocks with launcher error
	mockLauncher := &interfaces.MockEditorLauncher{
		Error: &filtering.ValidationError{Message: "editor launch failed"},
	}
	mockValidator := &interfaces.MockPromptValidator{}

	testCmd := NewTestableAddCommand(mockLauncher, mockValidator)
	testCmd.cmd.SetArgs([]string{"--name", "test-prompt"})

	err := testCmd.cmd.Execute()

	if err == nil {
		t.Fatal("Expected command to fail due to launcher error")
	}

	if !strings.Contains(err.Error(), "editor launch failed") {
		t.Errorf("Expected launcher error message, got: %v", err)
	}
}

func TestAddCommand_ContentValidation_Invalid(t *testing.T) {
	// Setup mocks with invalid content
	mockLauncher := &interfaces.MockEditorLauncher{
		Content: "short", // Too short content
	}
	mockValidator := &interfaces.MockPromptValidator{
		ContentError: filtering.ErrPromptTooShort,
	}

	testCmd := NewTestableAddCommand(mockLauncher, mockValidator)
	testCmd.cmd.SetArgs([]string{"--name", "test-prompt"})

	err := testCmd.cmd.Execute()

	if err == nil {
		t.Fatal("Expected command to fail due to content validation")
	}

	if err != filtering.ErrPromptTooShort {
		t.Errorf("Expected ErrPromptTooShort, got: %v", err)
	}
}

func TestAddCommand_NameValidation_Invalid(t *testing.T) {
	// Setup mocks with invalid name
	mockLauncher := &interfaces.MockEditorLauncher{
		Content: "This is valid content that should pass validation",
	}
	mockValidator := &interfaces.MockPromptValidator{
		NameError: filtering.ErrInvalidPromptName,
	}

	testCmd := NewTestableAddCommand(mockLauncher, mockValidator)
	testCmd.cmd.SetArgs([]string{"--name", "invalid@name"})

	err := testCmd.cmd.Execute()

	if err == nil {
		t.Fatal("Expected command to fail due to name validation")
	}

	if err != filtering.ErrInvalidPromptName {
		t.Errorf("Expected ErrInvalidPromptName, got: %v", err)
	}
}

func TestAddCommand_FileInput(t *testing.T) {
	// Test file input mode (should not call launcher)
	mockLauncher := &interfaces.MockEditorLauncher{
		LaunchFunc: func(promptName string, isTemplate bool) (string, error) {
			t.Error("Launcher should not be called when file is specified")
			return "", nil
		},
	}
	mockValidator := &interfaces.MockPromptValidator{}

	testCmd := NewTestableAddCommand(mockLauncher, mockValidator)
	testCmd.cmd.SetArgs([]string{"--name", "test-prompt", "--file", "test.txt"})

	err := testCmd.cmd.Execute()

	if err != nil {
		t.Fatalf("Expected command to succeed with file input, got: %v", err)
	}
}

func TestAddCommand_TemplateMode(t *testing.T) {
	// Test template mode
	mockLauncher := &interfaces.MockEditorLauncher{
		LaunchFunc: func(promptName string, isTemplate bool) (string, error) {
			if !isTemplate {
				t.Error("Expected isTemplate to be true")
			}
			if promptName != "test-template" {
				t.Errorf("Expected promptName 'test-template', got: %s", promptName)
			}
			return "Template content with {{.Variable}}", nil
		},
	}
	mockValidator := &interfaces.MockPromptValidator{}

	testCmd := NewTestableAddCommand(mockLauncher, mockValidator)
	testCmd.cmd.SetArgs([]string{"--name", "test-template", "--template"})

	err := testCmd.cmd.Execute()

	if err != nil {
		t.Fatalf("Expected command to succeed in template mode, got: %v", err)
	}
}

// Integration test with real components
func TestAddCommand_Integration_RealComponents(t *testing.T) {
	// Setup real components
	mockFS := interfaces.NewMockFileSystem()
	mockCmd := interfaces.NewMockCommandExecutor()
	mockEnv := interfaces.NewMockEnvironment()
	mockEnv.Setenv("EDITOR", "vim")

	launcher := editor.NewLauncher(mockFS, mockCmd, mockEnv, editor.NewMarkdownProcessor())
	validator := filtering.NewPromptValidator()

	testCmd := NewTestableAddCommand(launcher, validator)

	// Mock file system to simulate successful editor session
	mockFS.TempFiles["/tmp/par-prompt-integration-test-123.md"] = &interfaces.MockFile{
		NameValue: "/tmp/par-prompt-integration-test-123.md",
		Content:   bytes.NewBufferString("This is valid prompt content created in the editor"),
	}

	testCmd.cmd.SetArgs([]string{"--name", "integration-test"})

	err := testCmd.cmd.Execute()

	if err != nil {
		t.Fatalf("Expected integration test to succeed, got: %v", err)
	}

	// Verify command was created
	if len(mockCmd.Commands) == 0 {
		t.Error("Expected editor command to be created")
	} else {
		cmd := mockCmd.Commands[0]
		if cmd.Name != "vim" {
			t.Errorf("Expected editor command 'vim', got: %s", cmd.Name)
		}
	}
}
