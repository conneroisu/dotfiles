
sudo cp -r ./.config/nixos/ /etc/
sudo nixos-rebuild switch --flake /etc/nixos
make stow
