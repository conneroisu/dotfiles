# Shell Utilities Specification

## ADDED Requirements

### Requirement: Fuzzy File Opening (nvimf)
The system SHALL provide an `nvimf` command that enables interactive fuzzy file selection with syntax-highlighted preview and opens the selected file in Neovim.

#### Scenario: Interactive file selection
- **WHEN** user runs `nvimf` without arguments in a directory
- **THEN** the system displays an interactive fuzzy finder listing all files in the current directory and subdirectories
- **AND** shows a syntax-highlighted preview using bat for the selected file
- **AND** opens the selected file in Neovim upon confirmation

#### Scenario: No file selected
- **WHEN** user runs `nvimf` and cancels the selection (ESC or Ctrl-C)
- **THEN** the system exits without opening any file
- **AND** returns a zero exit code (graceful cancellation)

#### Scenario: Empty directory
- **WHEN** user runs `nvimf` in a directory with no files
- **THEN** the system displays an empty fuzzy finder
- **AND** exits gracefully when canceled

#### Scenario: Editor integration
- **WHEN** user selects a file from the fuzzy finder
- **THEN** the system opens the file in Neovim
- **AND** preserves the terminal state and working directory

### Requirement: Cross-Platform File Selection Deployment
The `nvimf` program SHALL be deployed as a packaged Nix derivation with proper dependency management.

#### Scenario: NixOS installation
- **WHEN** nvimf module is enabled on a NixOS system
- **THEN** the `nvimf` command is available in system PATH
- **AND** required dependencies (fzf, bat, neovim) are automatically available

#### Scenario: Darwin installation
- **WHEN** nvimf module is enabled on a macOS system via nix-darwin
- **THEN** the `nvimf` command is available in system PATH
- **AND** required dependencies are automatically available

#### Scenario: Engineer feature integration
- **WHEN** the engineer feature is enabled
- **THEN** nvimf is automatically available alongside other development tools

### Requirement: Preview and Dependency Management
The nvimf program SHALL explicitly declare its runtime dependencies (fzf, bat, neovim) and provide syntax-highlighted file previews.

#### Scenario: Syntax highlighting in preview
- **WHEN** user navigates through files in the fuzzy finder
- **THEN** the preview pane shows syntax-highlighted content for recognized file types
- **AND** uses bat's automatic language detection

#### Scenario: Missing dependencies handled by Nix
- **WHEN** nvimf module is installed via Nix
- **THEN** all runtime dependencies are available in the wrapped script's PATH
- **AND** the script does not fail due to missing commands

#### Scenario: Script wrapper isolation
- **WHEN** nvimf script is executed
- **THEN** it uses the Nix-provided versions of fzf, bat, and neovim
- **AND** does not rely on system-installed versions of these tools
