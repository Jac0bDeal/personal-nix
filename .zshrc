alias nix-rebuild='darwin-rebuild switch --flake /etc/nix-darwin#work'
alias nix-edit='vim /etc/nix-darwin/flake.nix'
alias nix-update='nix flake update --flake /etc/nix-darwin'
alias nix-cleanup='sudo nix-collect-garbage -d'
