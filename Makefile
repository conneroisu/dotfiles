
stow:
	sh ./scripts/stow.sh
nix: 
	darwin-rebuild switch --flake ~/.config/nix-darwin

nixos-init:
	sudo cp /etc/nixos/hardware-configuration.nix ./.config/nixos/hardware-configuration.nix
	make nixos
	
nixos: 
	sudo cp -r ./.config/nixos/ /etc/
	sudo nixos-rebuild switch --flake /etc/nixos
	make stow
	

check:
	cd ./.config/nixos/ && nix flake check
	cd ./.config/nix-darwin/ && nix flake check

fmt: 
	cd ./.config/nixos/ && nixfmt .
	cd ./.config/nix-darwin/ && nixfmt .
