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

### Go dev shell

> WARNING: It only provides the shell commands (go, gopls, etc), not a way to build a package.
> This template is only useful to avoid installing go globally.

```sh
nix flake init -t github:connsoisu/nix-config#go-shell
```

### Laravel dev shell

> WARNING: It only provides the shell commands (php, composer, etc), not a way to build a package.
> This template is only useful to avoid installing Laravel globally.

```sh
nix flake init -t github:connsoisu/nix-config#laravel-shell
```

Adding a package build is as simple as:
```nix 
{
  inputs.nix-config.url = "github:connsoisu/nix-config";
  outputs = {
    self,
    nixpkgs,
    nix-config,
  }: let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
  in {
    packages.x86_64-linux.default = pkgs.buildGoModule {
      pname = "my-go-project";
      version = "0.0.1";
      src = ./.;
      vendorSha256 = "sha256-0s0m0m0";
      doCheck = false;
      meta = with pkgs.lib; {
        description = "My Go project";
        homepage = "https://github.com/my-go-project";
        license = licenses.asl20;
        maintainers = with maintainers; [conneroheisorge];
      };
    };
  };
}
```
