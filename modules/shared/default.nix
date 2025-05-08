{
  lib,
  pkgs,
  inputs,
  system,
  namespace,
  ...
}: {
  programs = {
    direnv.enable = true;
    direnv.nix-direnv.enable = true;
    ssh = {
      extraConfig = ''
        SetEnv TERM=xterm-256color
      '';
    };
  };

  environment = {
    etc."nix/nix.custom.conf".text = let
      # This function converts an attribute set to Nix configuration lines
      settingsToConf = settings:
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList (
            name: value: "${name} = ${
              if builtins.isBool value
              then lib.boolToString value
              else if builtins.isInt value
              then toString value
              else if builtins.isList value
              then lib.concatMapStringsSep " " (x: "${toString x}") value
              else if builtins.isString value
              then value
              else throw "Unsupported type for nix.conf setting ${name}"
            }"
          )
          settings
        );
    in
      # Apply the function to your desired settings
      settingsToConf {
        # Add your nix settings here, for example:
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [
          "root"
          "@wheel"
          "connerohnesorge"
        ];
        allowed-users = [
          "root"
          "@wheel"
          "connerohnesorge"
        ];
      };

    variables = {
      EDITOR = "nvim";
      SHELL = "zsh";
      GTK_THEME = "adw-gtk3-dark";
    };

    systemPackages =
      (with pkgs."${namespace}"; [
        httptap
        catls
        convert_img
        python-venv
      ])
      ++ (with inputs; [
        zen-browser.packages."${system}".default
        nh.packages."${system}".default
        blink.packages."${system}".default
        blink.packages."${system}".blink-fuzzy-lib
        codex.packages."${system}".default
      ])
      ++ (with pkgs; [
        doppler
        pandoc
        bun
        ollama
        git
        zsh
        nushell
        carapace
        git-lfs
        stow
        age
        nushell
        coder
        zed-editor
        nix-index
        file
        jujutsu

        # Apps
        obsidian
        neovim
        brave
        spotify
        discord
        telegram-desktop

        # Shell
        zinit
        starship
        direnv
        nix-direnv
        bat
        wget
        fd
        jq
        yq
        spicetify-cli
        fzf
        zellij
        atuin
        zoxide
        eza
        delta
        unzip
        htop
        tealdeer
        sleek
        tree-sitter
        unixtools.xxd
        ffmpeg
        tree
        uv
        sad
        ripgrep

        # Communication
        tailscale
        dnsutils
        minicom

        sqlite
        sqlite-vec
        pkg-config

        # Platforms
        flyctl
        fh
        gh
        tea

        # Languages
        nixd
        statix
        nodejs
        lua-language-server
      ]);
  };

  fonts.packages = with pkgs; [
    nerd-fonts.code-new-roman
    corefonts
    vistafonts
  ];
  # ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
}
