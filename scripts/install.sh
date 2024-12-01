#!/bin/bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
  sh -s -- install

zypper --non-interactive in \
    git \
    git-lfs \
    git-delta

git config --global init.defaultBranch main

################################################################################
git config --global user.name "Conner Ohnesorge"
git config --global user.email conneroisu@outlook.com



zypper ar -f https://download.opensuse.org/repositories/system:/snappy/openSUSE_Tumbleweed/ snappy
zypper ar https://download.opensuse.org/repositories/isv:/Rancher:/stable/rpm/isv:Rancher:stable.repo
zypper ar https://download.opensuse.org/repositories/devel:languages:python:numeric/openSUSE_Tumbleweed/devel:languages:python:numeric.repo
zypper ar https://download.opensuse.org/repositories/Education/openSUSE_Tumbleweed/Education.repo
zypper ar https://download.opensuse.org/repositories/openSUSE:Factory/standard/openSUSE:Factory.repo
zypper refresh



zypper --gpg-auto-import-keys refresh
zypper dup --from snappy


sudo zypper in libvpx-devel
zypper in libzip-devel libzip-tools
sudo zypper in librsvg-devel
sudo zypper in virtualbox virtualbox-devel
zypper update

sudo zypper --non-interactive in --force \
    docker-compose \
    yast2-docker \
    cargo \
    gcc-c++ \
    libdisplay-info-devel \
    aquamarine-debugsource aquamarine-devel libaquamarine2 libaquamarine2-debuginfo \
    hyprutils-devel \
    hyprlang-devel \
    meson \
    cmake \
    "pkgconfig(cairo)" \
    "pkgconfig(egl)" \
    "pkgconfig(gbm)" \
    "pkgconfig(gl)" \
    "pkgconfig(glesv2)" \
    "pkgconfig(libdrm)" \
    "pkgconfig(libinput)" \
    "pkgconfig(libseat)" \
    "pkgconfig(libudev)" \
    "pkgconfig(pango)" \
    "pkgconfig(pangocairo)" \
    "pkgconfig(pixman-1)" \
    "pkgconfig(vulkan)" \
    "pkgconfig(wayland-client)" \
    "pkgconfig(wayland-protocols)" \
    "pkgconfig(wayland-scanner)" \
    "pkgconfig(wayland-server)" \
    "pkgconfig(xcb)" \
    "pkgconfig(xcb-icccm)" \
    "pkgconfig(xcb-renderutil)" \
    "pkgconfig(xkbcommon)" \
    "pkgconfig(xwayland)" \
    "pkgconfig(xcb-errors)" \
    scdoc \
    hyprcursor \
    hyprwayland-scanner \
    glslang-devel \
    Mesa-libGLESv3-devel \
    tomlplusplus-devel \
    hyprland \
    hyprpicker \
    hyprpaper 

    lua-language-server \
    ruby-devel \
    sox \
    emacs \
    neovim \
    wlsunset \
    dunst \
    gtkwave \
    bat \
    lazygit \
    ripgrep \
    fzf \
    gcc-ada \
    fd \
    jq \
    sad \
    latexmk \
    texlive-scheme-full \
    zellij \
    texlive-latex-recommended \
    libgtop-devel \
    libgtop \
    aylurs-gtk-shell \
    bluez \
    htop \
    docker \
    docker-compose \
    docker-compose-switch \
    waydroid \
    awk \
    gh \
    podman \
    rancher-desktop \
    gparted \
    gum \
    gamescope \
    steam \
    steam-devices \
    alsa \
    alsa-utils \
    alsa-devel \
    snapd \
    python311-black \
    python311-numpy \
    python311-pandas \
    python311-scipy \
    python311-matplotlib \
    python311-scikit-learn \
    python311-scikit-image \
    python311-torch \
    python311-opencv \
    python311-requests \
    python311-pyqt5 \
    python311-pyarrow \
    python311-mysqlclient \
    python311-xdg \ 
    openssl \
    kernel-firmware-intel \
    rustup \
    pyenv \
    stow

# Install uv (python)
curl -LsSf https://astral.sh/uv/install.sh | sh
# Install flyctl
curl -L https://fly.io/install.sh | sh
# Install zen-browser
bash <(curl https://updates.zen-browser.app/appimage.sh)
# Install bun
curl -fsSL https://bun.sh/install | bash && \
    sudo ln -s $HOME/.bun/bin/bun /usr/local/bin/bun

bun install -g sass

# Install Hyprpanels
# Installs HyprPanel to ~/.config/ags
git clone https://github.com/Jas-SinghFSU/HyprPanel.git && \
  ln -s $(pwd)/HyprPanel $HOME/.config/ags

zypper refresh

rustup toolchain install stable

# Rust
cargo install --locked zellij
cargo install vhdl_ls \
            cargo-make \
            cargo-watch \
            cargo-edit \
            cargo-tree \
            cargo-bloat \
            cargo-expand \
            tealdeer \
            sleek

# Ruby
gem install neovim

# Javascript
npm install -g neovim

# Brew
brew install go-task 

# Git
git config --global push.autoSetupRemote true

hyprpm add https://github.com/hyprwm/hyprland-plugins
hyprpm enable hyprexpo
#
# ARCHITECTURE="$(uname -m)-linux"
# json=$(curl -s https://ziglang.org/download/index.json)
#
# url=$(echo "$json" | jq -r ".master.\"$ARCHITECTURE\".tarball")
# expected_sha=$(echo "$json" | jq -r ".master.\"$ARCHITECTURE\".shasum")
#
# curl -O "$url"
#
# actual_sha=$(shasum -a 256 zig*.tar.xz | awk '{print $1}')
# if [ "$expected_sha" != "$actual_sha" ]; then
#   echo "SHA checksum verification failed."
#   echo "Expected: $expected_sha"
#   echo "Actual: $actual_sha"
#   exit 1
# fi
#
# if [ ! -d "zig-master-latest" ]; then
#   mkdir zig-master-latest
# fi
#
# tar -xf zig*.tar.xz -C zig-master-latest --strip-components=1
# rm zig*.tar.xz
git clone https://github.com/zigtools/zls
cd zls
zig build -Doptimize=ReleaseSafe
mv ./zig-out/bin/zls /usr/local/bin/zls

sudo usermod -aG vboxusers connerohnesorge
