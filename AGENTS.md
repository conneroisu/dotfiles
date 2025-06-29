# AGENTS.md - Coding Agent Guidelines

## Build/Test Commands
- **Lint**: `nix develop -c lint` (runs statix, deadnix, nix flake check)
- **Format**: `nix fmt` (alejandra for Nix, rustfmt, black for Python)
- **Single Test**: `cd modules/programs/convert_img && python -m pytest tests/test_convert_img.py::TestClassName::test_method`
- **Build Module**: `cd modules/programs/<program-name> && nix build`
- **Rebuild System**: `darwin-rebuild switch --flake .` (macOS) or `sudo nixos-rebuild switch --flake .` (NixOS)

## Code Style Guidelines
- **Nix**: Use alejandra formatting, prefer `let...in` blocks, use `delib.module` pattern for modules
- **Python**: Black formatting, type hints required, docstrings for classes/functions, pytest for tests
- **Imports**: Group by stdlib, third-party, local; use explicit imports over wildcards
- **Naming**: snake_case for files/functions, PascalCase for classes, kebab-case for Nix attributes
- **Error Handling**: Use proper exception types, validate inputs early, provide meaningful error messages
- **Module Structure**: Features in `modules/features/`, programs in `modules/programs/`, configs in `modules/config/`

## Architecture Notes
- Uses Denix framework for modular configuration management
- Platform-specific sections: `nixos.ifEnabled`, `darwin.ifEnabled`, `home.ifEnabled`
- Auto-discovery from `./hosts ./modules ./rices` paths
- Feature dependencies resolved automatically through module system