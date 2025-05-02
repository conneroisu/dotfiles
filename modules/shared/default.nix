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
        catls
        convert_img
        python-venv
      ])
      ++ (with inputs; [
        zen-browser.packages."${system}".default
        nh.packages."${system}".default
        blink.packages."${system}".default
        blink.packages."${system}".blink-fuzzy-lib
      ])
      ++ (with pkgs; [
        doppler
        bun
        carapace
        basedpyright
        nushell
        ollama
        fish
        tmux
        git
        zsh
        git-lfs
        cloc
        gnumake
        cmake
        stow
        age
        glow

        # Apps
        obsidian
        neovim
        vscode
        gtkwave
        brave
        spotify
        discord
        telegram-desktop
        jetbrains.datagrip

        # Shell
        zinit
        starship
        pkgs.direnv
        pkgs.nix-direnv
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

        # Communication
        tailscale
        dnsutils
        minicom

        gcc
        llvm
        nodejs
        ripgrep
        meson
        sqlite
        sqlite-vec
        pkg-config

        # Platforms
        turso-cli
        flyctl
        fh
        gh
        tea
        lakectl

        # Languages
        ## JS/TS
        nodejs
        jq-lsp
        rustup
        ## Nix
        nixd
        statix
        nix-search-cli

        ## Lua
        lua-language-server

        ## HTMX
        htmx-lsp
        tailwindcss

        ## Latex
        texlab
        ltex-ls

        ## Bash
        shellcheck
        yaml-language-server
        actionlint
        sqls

        vscode-langservers-extracted
        luajitPackages.luarocks

        # Formatters
        hclfmt
        shfmt
        rustfmt
        black
        alejandra
        cbfmt
        marksman
        pandoc
        harper
      ]);
  };

  fonts.packages = with pkgs;
    [
      nerd-fonts.code-new-roman
      corefonts
      vistafonts
    ]
    ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
}
