{
  description = "A development shell for rust";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    # self,
    nixpkgs,
    fenix,
    ...
  }: let
    # Define systems
    systems = [
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];

    # Helper function to generate per-system attributes
    forAllSystems = f: nixpkgs.lib.genAttrs systems f;

    # Define the devShell for each system
    mkDevShell = system: let
      pkgs = nixpkgs.legacyPackages.${system};
      fenixPkgs = fenix.packages.${system};
      rustChannel = "stable";
    in
      pkgs.mkShell {
        name = "dev";
        # Available packages on https://search.nixos.org/packages
        buildInputs = with pkgs; [
          alejandra # Nix
          nixd
          statix
          deadnix
          just
          (fenixPkgs.combine [
            fenixPkgs.${rustChannel}.toolchain
            # https://doc.rust-lang.org/rustc/platform-support.html
            # For more targets add:
            # fenixPkgs.targets.aarch64-linux-android."${rustChannel}".rust-std
            # fenixPkgs.targets.x86_64-linux-android."${rustChannel}".rust-std
          ])
        ];
        shellHook = ''
          echo "Welcome to the rust devshell!"
        '';
        # use a folder per toolchain name to store rust's cache
        CARGO_HOME = "$HOME/${fenixPkgs.${rustChannel}.toolchain.name}/.cargo";
        RUSTUP_HOME = "$HOME/${fenixPkgs.${rustChannel}.toolchain.name}/.rustup";
      };
  in {
    # Define devShells for all systems
    devShells = forAllSystems (system: {
      default = mkDevShell system;
    });
  };
}
