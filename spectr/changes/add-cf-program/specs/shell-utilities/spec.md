# Shell Utilities Specification

## ADDED Requirements

### Requirement: Fuzzy Directory Navigation (cf)
The system SHALL provide a `cf` command that enables interactive fuzzy directory selection with preview.

#### Scenario: Interactive directory selection
- **WHEN** user runs `cf` without arguments
- **THEN** the system displays an interactive fuzzy finder listing all directories (including hidden ones, excluding .git)
- **AND** shows a preview of directory contents for the selected item
- **AND** changes to the selected directory upon confirmation

#### Scenario: No directory selected
- **WHEN** user runs `cf` and cancels the selection (ESC or Ctrl-C)
- **THEN** the system exits without changing directory
- **AND** returns to the original working directory

#### Scenario: Empty directory tree
- **WHEN** user runs `cf` in a location with no subdirectories
- **THEN** the system displays an empty fuzzy finder
- **AND** exits without error when canceled

### Requirement: Cross-Platform Shell Script Deployment
The `cf` program SHALL be deployed as a packaged Nix derivation with proper dependency management.

#### Scenario: NixOS installation
- **WHEN** cf module is enabled on a NixOS system
- **THEN** the `cf` command is available in system PATH
- **AND** required dependencies (fd, fzf, ls) are automatically available

#### Scenario: Darwin installation
- **WHEN** cf module is enabled on a macOS system via nix-darwin
- **THEN** the `cf` command is available in system PATH
- **AND** required dependencies are automatically available

#### Scenario: Engineer feature integration
- **WHEN** the engineer feature is enabled
- **THEN** cf is automatically available alongside other development tools

### Requirement: Dependency Management
The cf program SHALL explicitly declare its runtime dependencies (fd-find, fzf, coreutils).

#### Scenario: Missing dependencies handled by Nix
- **WHEN** cf module is installed via Nix
- **THEN** all runtime dependencies are available in the wrapped script's PATH
- **AND** the script does not fail due to missing commands

#### Scenario: Script wrapper isolation
- **WHEN** cf script is executed
- **THEN** it uses the Nix-provided versions of fd, fzf, and ls
- **AND** does not rely on system-installed versions of these tools
