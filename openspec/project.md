# Project Context

## Purpose
This is a modular NixOS/Home Manager dotfiles repository using the **Denix** framework for cross-platform configuration management. The project provides unified, type-safe configuration across:
- NixOS systems (Linux)
- macOS systems (via nix-darwin)
- Standalone Home Manager deployments

**Goals**:
- Maintain reproducible, declarative system configurations
- Enable feature-based modular architecture with automatic dependency resolution
- Provide consistent theming and user experience across platforms
- Package custom programs with cross-platform deployment
- Offer development templates for quick project bootstrapping

## Tech Stack

### Core Technologies
- **Nix**: Declarative package management and system configuration
- **NixOS**: Linux distribution built on Nix
- **Home Manager**: User environment management
- **nix-darwin**: Nix-based macOS system configuration
- **Denix**: Framework for modular, type-safe configuration with automatic discovery

### Window Management & Desktop
- **Hyprland**: Wayland compositor for Linux desktop environments
- **Stylix**: Theme system with Base16 color scheme integration

### Custom Programs (modules/programs/)
- **Go**: `cmbd` (clipboard manager), `kiro` (custom tools)
- **Python**: `convert_img` (image conversion utility with pytest tests)
- **Ruby**: `catls` (enhanced directory listing)
- **Shell**: `dx` (development environment helper)

### External Integrations
- **zen-browser**: Custom Firefox-based browser
- **proton-authenticator**: Authentication integration
- **conclaude**: Claude AI CLI integration
- **nordvpn**: VPN configuration
- **ghostty**: Terminal emulator

### Development Tools
- **treefmt-nix**: Code formatting
- **statix**: Nix linting
- **deadnix**: Dead code detection
- **nix-index-database**: Fast package search
- **sops-nix**: Secrets management
- **disko**: Declarative disk partitioning

## Project Conventions

### Code Style
- **Formatting**: Use `nix fmt` (treefmt) for all Nix code
- **Linting**: Run `nix develop -c lint` before commits (statix + deadnix)
- **File Naming**:
  - Module files: lowercase with hyphens (e.g., `audio.nix`, `convert_img/`)
  - Constants: camelCase for options (e.g., `myconfig.features.featureName`)
- **Module Structure**: Use Denix patterns with explicit platform sections
- **Indentation**: 2 spaces (enforced by treefmt)
- **No emojis**: Unless explicitly requested in tests/documentation

### Architecture Patterns

#### Module System (Denix Framework)
**Feature Modules** (`modules/features/`):
```nix
delib.module {
  name = "feature-name";
  options.myconfig.features.featureName = singleEnableOption false;
  nixos.ifEnabled = { /* NixOS config */ };
  darwin.ifEnabled = { /* macOS config */ };
  home.ifEnabled = { /* Home Manager config */ };
}
```

**Host Configurations** (`hosts/`):
```nix
delib.host {
  type = "desktop"; # or "laptop", "server"
  features = { featureName = true; };
  rice = "dark";
  nixos = { /* platform-specific */ };
  darwin = { /* platform-specific */ };
}
```

**Custom Programs** (`modules/programs/`):
- Self-contained directories with source + `default.nix`
- Cross-platform package definitions
- Automatic integration into system packages

#### Configuration Modules (`modules/config/`)
- `constants.nix`: Read-only user constants (username, email, etc.)
- `user.nix`: User account configuration
- `hosts.nix`: Host type definitions and feature mappings
- `args.nix`: Shared arguments between nixos/home-manager
- `home.nix`: Home Manager patterns
- `rices.nix`: Theme system configuration

#### Theme System (`rices/`)
- Stylix integration with Base16 color schemes
- Consistent theming across all applications
- Per-host theme selection via `rice` attribute

### Testing Strategy

#### Module Testing
- **Feature modules**: `nix flake check` validates all outputs
- **Program modules**: `cd modules/programs/<name> && nix build`
- **NixOS configs**: `nixos-rebuild build --flake . --show-trace`
- **Darwin configs**: `darwin-rebuild switch --flake . --show-trace`

#### Program-Specific Testing
- **Python programs**: `cd modules/programs/convert_img && python -m pytest tests/`
- **Manual testing**: Edit any program → run manually to verify functionality
- **Integration testing**: CI/CD via GitHub Actions (`.github/workflows/ci.yml`)

#### Pre-Commit Checks
1. Run `nix develop -c lint` (statix, deadnix, nix flake check)
2. Run `nix fmt` for formatting
3. Build affected configurations without switching
4. Test modified programs manually

#### Important Testing Note
From `CLAUDE.md`: "If you ever write tests, you must actually verify that they work."

### Git Workflow
- **Main Branch**: `main` (target for PRs)
- **Feature Branches**: Named descriptively (e.g., `update-n-hype`)
- **CI/CD**: GitHub Actions runs on all commits
- **Commit Style**: Descriptive messages, no enforced convention
- **Submodules**: Recursive clone required (`git clone --recurse-submodules`)

## Domain Context

### Nix Ecosystem Knowledge
- **Flakes**: Modern Nix package/configuration format with `flake.nix` entry point
- **Derivations**: Build instructions for packages (`.drv` files)
- **Nixpkgs**: Central package repository (using `nixos-unstable` channel)
- **Overlays**: Mechanism to modify/extend nixpkgs
- **Options**: Typed configuration parameters with automatic validation

### Denix Framework Specifics
- **Automatic Discovery**: Modules in `paths = [./hosts ./modules ./rices]` are auto-loaded
- **Type Safety**: Leverages Nix's module system for type-safe configurations
- **Platform Abstraction**: Single module definition works across nixos/darwin/home
- **Feature Dependencies**: Automatic resolution (e.g., `engineer` enables dev tools)

### Multi-Platform Considerations
- **NixOS**: Full system configuration including kernel, services, users
- **Darwin**: macOS system configuration (limited compared to NixOS)
- **Home Manager**: User-space configuration (works on all platforms)
- **Conditional Logic**: Use platform-specific sections to handle differences

## Important Constraints

### Technical Constraints
- **Nix Language Only**: All configuration must be valid Nix expressions
- **Reproducibility**: Builds must be deterministic and reproducible
- **Purity**: No network access during builds (except fixed-output derivations)
- **Platform Support**: Must maintain compatibility across NixOS, Darwin, and Home Manager
- **Denix Framework**: Must follow Denix patterns for module structure

### Development Environment
- **Commands**: Must run via `nix develop -c <command>` for correct shell environment
- **MCP Tools**: Use `nixos` and `context7` MCP servers for background info
- **Testing**: All program edits require manual verification + automated tests

### Breaking Changes
- Changes affecting multiple hosts require testing on representative systems
- Theme changes must verify Stylix integration remains functional
- Feature dependency changes need validation across all dependent features

## External Dependencies

### Flake Inputs (Primary)
- **nixpkgs**: `github:nixos/nixpkgs/nixos-unstable`
- **home-manager**: `github:nix-community/home-manager/master`
- **nix-darwin**: `github:nix-darwin/nix-darwin/master`
- **denix**: `github:yunfachi/denix` (core framework)
- **stylix**: `https://flakehub.com/f/danth/stylix/0.1.776`
- **hyprland**: `github:hyprwm/hyprland`

### Custom Flake Inputs
- **zen-browser**: `github:conneroisu/zen-browser-flake`
- **proton-authenticator**: `github:conneroisu/proton-authenticator-flake`
- **conclaude**: `github:connix-io/conclaude`
- **kiro-flake**: `github:conneroisu/kiro-flake`
- **nordvpn**: `github:conneroisu/nordvpn-flake`

### System Services
- **NixOS-WSL**: `github:nix-community/NixOS-WSL/main` (Windows Subsystem for Linux)
- **nixos-hardware**: `github:NixOS/nixos-hardware/master` (hardware-specific configs)
- **nix-ld**: `github:Mic92/nix-ld` (dynamic library loading compatibility)

### Development Tools
- **treefmt-nix**: `github:numtide/treefmt-nix` (multi-formatter)
- **nix-index-database**: `github:nix-community/nix-index-database` (package search)
- **sops-nix**: `github:Mic92/sops-nix` (secrets management)
- **disko**: `github:nix-community/disko` (declarative disk setup)
- **nix-ai-tools**: `github:numtide/nix-ai-tools`

### CI/CD
- **GitHub Actions**: Automated testing and validation on push
- **Determinate Systems**: `https://flakehub.com/f/DeterminateSystems/determinate/*`
