{
  description = "Personal System Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
  let
    configuration = { pkgs, config, ... }: {

      nixpkgs.config.allowUnfree = true;

      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [
          pkgs.alacritty
          pkgs.discord
          pkgs.fzf
          pkgs.gh
          pkgs.git
          pkgs.gnumake
          pkgs.gnupg
          pkgs.gnused
          pkgs.gobject-introspection
          pkgs.go_1_24
          pkgs.gotools
          pkgs.golangci-lint
          pkgs.htop
          pkgs.jetbrains.goland
          pkgs.jetbrains.pycharm-community
          pkgs.jetbrains.rust-rover
          pkgs.jq
          pkgs.mkalias
          pkgs.neovim
          pkgs.openssl_3
          pkgs.pinentry_mac
          pkgs.podman
          pkgs.podman-compose
          pkgs.podman-desktop
          pkgs.python311
          pkgs.stow
          pkgs.the-unarchiver
          pkgs.tmux
          pkgs.zoxide
          pkgs.zsh-powerlevel10k
        ];

      homebrew = {
        enable = true;
        brews = [
          "mas"
        ];
        casks = [
          "nordvpn"
        ];
        masApps = {
          "AdGuard for Safari" = 1440147259;
          "Kagi for Safari" = 1622835804;
          "Magnet" = 441258766;
          "Mapper for Safari" = 1589391989;
          "Yoink" = 457622435;
        };
        onActivation.cleanup = "zap";
        onActivation.autoUpdate = true;
        onActivation.upgrade = true;
      };

      fonts.packages = [
        pkgs.nerd-fonts.jetbrains-mono
      ];

      system.activationScripts.applications.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        };
      in
        pkgs.lib.mkForce ''
          # Set up applications.
          echo "setting up /Applications..." >&2
          rm -rf /Applications/Nix\ Apps
          mkdir -p /Applications/Nix\ Apps
          find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
          while read -r src; do
            app_name=$(basename "$src")
            echo "copying $src" >&2
            ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
          done
        '';

      security.pam.services.sudo_local.touchIdAuth = true;

      system.defaults = {
        dock.autohide = true;
        dock.mru-spaces = false;
        dock.persistent-apps = [
          "/System/Applications/Launchpad.app"
          "/System/Applications/Mail.app"
          "/System/Applications/Calendar.app"
          "/Applications/Safari.app"
          "${pkgs.jetbrains.goland}/Applications/Goland.app"
          "${pkgs.jetbrains.pycharm-community}/Applications/Pycharm CE.app"
          "${pkgs.jetbrains.rust-rover}/Applications/RustRover.app"
          "${pkgs.alacritty}/Applications/Alacritty.app"
          "${pkgs.discord}/Applications/Discord.app"
          "/System/Applications/System Settings.app"
        ];
        dock.show-recents = false;
        finder.AppleShowAllExtensions = true;
        finder.AppleShowAllFiles = true;
        finder.FXPreferredViewStyle = "clmv";
        finder.FXRemoveOldTrashItems = true;
        loginwindow.GuestEnabled = false;
        loginwindow.LoginwindowText = "Jacob's Hacking Machine";
        menuExtraClock.ShowDate = 0;
        menuExtraClock.ShowDayOfWeek = true;
        menuExtraClock.ShowSeconds = true;
        NSGlobalDomain.KeyRepeat = 2;
        screencapture.location = "~/Pictures/screenshots";
        screensaver.askForPasswordDelay = 10;
      };

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      nix.settings.download-buffer-size = 2147483648;

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#personal
    darwinConfigurations."personal" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            # Install Homebrew under the default prefix
            enable = true;

            # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
            enableRosetta = true;

            # User owning the Homebrew prefix
            user = "jacobdeal";
          };
        }
      ];
    };
  };
}
