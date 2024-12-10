{
  pkgs,
  pkgs-unstable,
  inputs,
  ...
}: {
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "connerohnesorge";
  home.homeDirectory = if pkgs.stdenv.isDarwin 
    then "/Users/connerohnesorge"
    else "/home/connerohnesorge";
  # Linux-only packages
  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11"; # Please read the comment before changing.

  home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello
    # pkgs.devenv

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
    ".zshrc".source = ./.zshrc;
    "vhdl_ls.toml".source = ./vhdl_ls.toml;
    ".vimrc".source = ./.vimrc;
    ".obsidian.vimrc".source = ./.obsidian.vimrc;
    "./.config/starship.toml".source = ./.config/starship.toml;
    "./.config/rofi/config.rasi".source = ./.config/rofi/config.rasi;
    "./.config/zellij/config.kdl".source = ./.config/zellij/config.kdl;
  };

  # Let Home Manager install and manage itself.
  programs = {
    home-manager.enable = true;
    git = {
      enable = true;
      lfs.enable = true;
      userName = "connerohnesorge";
      userEmail = "conneroisu@outlook.com";
      extraConfig = {
        push = {
          autoSetupRemote = true;
        };
      };
    };
  };
}
