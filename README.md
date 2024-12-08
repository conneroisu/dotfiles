# dotfiles - Conner Ohnesorge

## Introduction

dotfiles for my personal setup

## Installation

```bash
git clone --recurse-submodules -j8 https://github.com/conneroisu/dotfiles.git
cd dotfiles
make nixos-init
```

## Development


### Overlays

Found in `overlays/`, a nix overlay is a mechanism in the Nix package manager that allows you to customize and extend the existing package collection (nixpkgs) without modifying it directly. Think of it as a layer that sits on top of the default package definitions, where you can:

1. Override existing packages - modify their build instructions, dependencies, or versions
2. Add entirely new packages that don't exist in nixpkgs
3. Modify package attributes or metadata

Here's a simple example of a Nix overlay:

```nix
self: super: {
  # Override an existing package
  firefox = super.firefox.override {
    enableTridactyl = true;
  };

  # Add a new package
  myCustomPackage = self.stdenv.mkDerivation {
    name = "my-custom-package";
    # ... other package definition attributes
  };
}
```

The overlay function takes two parameters:
- `self`: The final package set after all overlays are applied
- `super`: The package set before the current overlay is applied

Overlays are composable, meaning you can stack multiple overlays on top of each other. They're commonly used for:
- Creating custom development environments
- Testing package modifications before submitting them to nixpkgs
- Maintaining organization-specific package modifications
- Using packages from different nixpkgs versions together
