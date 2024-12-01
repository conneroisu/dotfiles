
stow:
	cp -r ./.config/nix-darwin/ ~/.config/nix-darwin/
	stow --ignore=.git --ignore=Makefile --ignore=README.md --ignore=test.sh --ignore=Dockerfile --ignore=.config/ags --ignore=.config/nix-darwin .
nix: 
	make stow
	darwin-rebuild switch --flake ~/.config/nix-darwin
	

nixos-iso:
	nix build .#iso
	

nixos-init:
	sudo cp /etc/nixos/hardware-configuration.nix ./.config/nixos/hardware-configuration.nix
	make nixos
nixos: 
	
	sudo cp -r ./.config/nixos/ /etc/nixos/
	sudo nixos-rebuild switch --flake /etc/nixos
	make stow
	

check:
	cd ./.config/nixos/ && nix flake check
	cd ./.config/nix-darwin/ && nix flake check

fmt: 
	cd ./.config/nixos/ && nixfmt .
	cd ./.config/nix-darwin/ && nixfmt .
