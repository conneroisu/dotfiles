# Templates

### Basic dev shell

Apply to the current folder by running:

```sh
nix flake init -t github:conneroisu/nix-config#devshell
```

### Rust dev shell

> WARNING: It only provides the shell commands (cargo, rust-analyzer, etc), not a way to build a package.
> This template is only useful to avoid installing rust globally.

```sh
nix flake init -t github:connsoisu/nix-config#rust-shell
```
