
stow:
	stow --ignore=.git --ignore=Makefile --ignore=README.md --ignore=test.sh --ignore=Dockerfile --ignore=.config/ags --ignore=.config/nix-darwin .
nix: 
	cp -r ./.config/nix-darwin/ ~/.config/nix-darwin/
	make stow
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
