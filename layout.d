.
├── Makefile
├── README.md
├── Taskfile.yaml
├── flake.lock
├── flake.nix
├── home.nix
├── hosts
│   ├── darwin
│   │   └── default.nix
│   ├── nixos
│   │   └── default.nix
│   └── rhel
│       └── default.nix
├── layout.d
├── modules
│   ├── darwin
│   │   ├── packages.nix
│   │   └── secrets.nix
│   ├── linux
│   │   ├── packages.nix
│   │   └── secrets.nix
│   ├── nixos
│   │   ├── packages.nix
│   │   └── secrets.nix
│   └── shared
│       ├── default.nix
│       └── packages.nix
├── nixos-config
│   ├── LICENSE
│   ├── README.md
│   ├── apps
│   │   ├── README.md
│   │   ├── aarch64-darwin
│   │   │   ├── apply
│   │   │   ├── build
│   │   │   ├── build-switch
│   │   │   ├── check-keys
│   │   │   ├── copy-keys
│   │   │   ├── create-keys
│   │   │   └── rollback
│   │   ├── aarch64-linux -> x86_64-linux
│   │   ├── x86_64-darwin
│   │   │   ├── apply
│   │   │   ├── build
│   │   │   ├── build-switch
│   │   │   ├── check-keys
│   │   │   ├── copy-keys
│   │   │   └── create-keys
│   │   └── x86_64-linux
│   │       ├── apply
│   │       ├── build-switch
│   │       ├── check-keys
│   │       ├── copy-keys
│   │       ├── create-keys
│   │       ├── install
│   │       └── install-with-secrets
│   ├── flake.lock
│   ├── flake.nix
│   ├── hosts
│   │   ├── darwin
│   │   │   └── default.nix
│   │   └── nixos
│   │       └── default.nix
│   ├── modules
│   │   ├── darwin
│   │   │   ├── README.md
│   │   │   ├── casks.nix
│   │   │   ├── dock
│   │   │   │   └── default.nix
│   │   │   ├── files.nix
│   │   │   ├── home-manager.nix
│   │   │   ├── packages.nix
│   │   │   └── secrets.nix
│   │   ├── nixos
│   │   │   ├── README.md
│   │   │   ├── config
│   │   │   │   ├── login-wallpaper.png
│   │   │   │   ├── polybar
│   │   │   │   │   ├── bars.ini
│   │   │   │   │   ├── colors.ini
│   │   │   │   │   ├── config.ini
│   │   │   │   │   ├── modules.ini
│   │   │   │   │   └── user_modules.ini
│   │   │   │   └── rofi
│   │   │   │       ├── colors.rasi
│   │   │   │       ├── confirm.rasi
│   │   │   │       ├── launcher.rasi
│   │   │   │       ├── message.rasi
│   │   │   │       ├── networkmenu.rasi
│   │   │   │       ├── powermenu.rasi
│   │   │   │       └── styles.rasi
│   │   │   ├── disk-config.nix
│   │   │   ├── files.nix
│   │   │   ├── home-manager.nix
│   │   │   ├── packages.nix
│   │   │   └── secrets.nix
│   │   └── shared
│   │       ├── README.md
│   │       ├── cachix
│   │       │   └── default.nix
│   │       ├── config
│   │       │   ├── emacs
│   │       │   │   ├── config.org
│   │       │   │   └── init.el
│   │       │   └── p10k.zsh
│   │       ├── default.nix
│   │       ├── files.nix
│   │       ├── home-manager.nix
│   │       └── packages.nix
│   ├── overlays
│   │   ├── 10-feather-font.nix
│   │   └── README.md
│   └── templates
│       ├── starter
│       │   ├── apps
│       │   │   ├── aarch64-darwin
│       │   │   │   ├── apply
│       │   │   │   ├── build
│       │   │   │   ├── build-switch
│       │   │   │   └── rollback
│       │   │   ├── aarch64-linux -> x86_64-linux
│       │   │   ├── x86_64-darwin
│       │   │   │   ├── apply
│       │   │   │   ├── build
│       │   │   │   ├── build-switch
│       │   │   │   ├── check-keys
│       │   │   │   ├── copy-keys
│       │   │   │   └── create-keys
│       │   │   └── x86_64-linux
│       │   │       ├── apply
│       │   │       └── build-switch
│       │   ├── flake.nix
│       │   ├── hosts
│       │   │   ├── darwin
│       │   │   │   └── default.nix
│       │   │   └── nixos
│       │   │       └── default.nix
│       │   ├── modules
│       │   │   ├── darwin
│       │   │   │   ├── README.md
│       │   │   │   ├── casks.nix
│       │   │   │   ├── dock
│       │   │   │   │   └── default.nix
│       │   │   │   ├── files.nix
│       │   │   │   ├── home-manager.nix
│       │   │   │   └── packages.nix
│       │   │   ├── nixos
│       │   │   │   ├── README.md
│       │   │   │   ├── config
│       │   │   │   │   ├── login-wallpaper.png
│       │   │   │   │   ├── polybar
│       │   │   │   │   │   ├── bars.ini
│       │   │   │   │   │   ├── colors.ini
│       │   │   │   │   │   ├── config.ini
│       │   │   │   │   │   ├── modules.ini
│       │   │   │   │   │   └── user_modules.ini
│       │   │   │   │   └── rofi
│       │   │   │   │       ├── colors.rasi
│       │   │   │   │       ├── confirm.rasi
│       │   │   │   │       ├── launcher.rasi
│       │   │   │   │       ├── message.rasi
│       │   │   │   │       ├── networkmenu.rasi
│       │   │   │   │       ├── powermenu.rasi
│       │   │   │   │       └── styles.rasi
│       │   │   │   ├── disk-config.nix
│       │   │   │   ├── files.nix
│       │   │   │   ├── home-manager.nix
│       │   │   │   └── packages.nix
│       │   │   └── shared
│       │   │       ├── README.md
│       │   │       ├── config
│       │   │       │   ├── emacs
│       │   │       │   │   ├── config.org
│       │   │       │   │   └── init.el
│       │   │       │   └── p10k.zsh
│       │   │       ├── default.nix
│       │   │       ├── files.nix
│       │   │       ├── home-manager.nix
│       │   │       └── packages.nix
│       │   └── overlays
│       │       ├── 10-feather-font.nix
│       │       └── README.md
│       └── starter-with-secrets
│           ├── apps
│           │   ├── aarch64-darwin
│           │   │   ├── apply
│           │   │   ├── build
│           │   │   ├── build-switch
│           │   │   ├── check-keys
│           │   │   ├── copy-keys
│           │   │   ├── create-keys
│           │   │   └── rollback
│           │   ├── aarch64-linux -> x86_64-linux
│           │   ├── x86_64-darwin
│           │   │   ├── apply
│           │   │   ├── build
│           │   │   ├── build-switch
│           │   │   ├── check-keys
│           │   │   ├── copy-keys
│           │   │   └── create-keys
│           │   └── x86_64-linux
│           │       ├── apply
│           │       └── build-switch
│           ├── flake.nix
│           ├── hosts
│           │   ├── darwin
│           │   │   └── default.nix
│           │   └── nixos
│           │       └── default.nix
│           ├── modules
│           │   ├── darwin
│           │   │   ├── README.md
│           │   │   ├── casks.nix
│           │   │   ├── dock
│           │   │   │   └── default.nix
│           │   │   ├── files.nix
│           │   │   ├── home-manager.nix
│           │   │   ├── packages.nix
│           │   │   └── secrets.nix
│           │   ├── nixos
│           │   │   ├── README.md
│           │   │   ├── config
│           │   │   │   ├── login-wallpaper.png
│           │   │   │   ├── polybar
│           │   │   │   │   ├── bars.ini
│           │   │   │   │   ├── colors.ini
│           │   │   │   │   ├── config.ini
│           │   │   │   │   ├── modules.ini
│           │   │   │   │   └── user_modules.ini
│           │   │   │   └── rofi
│           │   │   │       ├── colors.rasi
│           │   │   │       ├── confirm.rasi
│           │   │   │       ├── launcher.rasi
│           │   │   │       ├── message.rasi
│           │   │   │       ├── networkmenu.rasi
│           │   │   │       ├── powermenu.rasi
│           │   │   │       └── styles.rasi
│           │   │   ├── disk-config.nix
│           │   │   ├── files.nix
│           │   │   ├── home-manager.nix
│           │   │   ├── packages.nix
│           │   │   └── secrets.nix
│           │   └── shared
│           │       ├── README.md
│           │       ├── config
│           │       │   ├── emacs
│           │       │   │   ├── config.org
│           │       │   │   └── init.el
│           │       │   └── p10k.zsh
│           │       ├── default.nix
│           │       ├── files.nix
│           │       ├── home-manager.nix
│           │       └── packages.nix
│           └── overlays
│               ├── 10-feather-font.nix
│               └── README.md
├── output.md
├── stow.sh
└── vhdl_ls.toml

72 directories, 188 files
