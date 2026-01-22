{
  description = "dotconfigs flake for macOS";
  inputs = {
    # source of all software which can be installed
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # for symlinking configs into typically expected locations
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # controls macos system settings
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs: {
    darwinConfigurations.Adams-MacBook-Pro = inputs.darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      pkgs = import inputs.nixpkgs {system = "aarch64-darwin";};
      modules = [
        ({pkgs, ...}: {
          # darwin preferences + configs
          programs.fish.enable = true;
          environment.shells = [pkgs.bash pkgs.zsh pkgs.fish];
          nix.extraOptions = ''
            experimental-features = nix-command flakes
          '';
          environment.systemPackages = [pkgs.coreutils];
          system.keyboard.enableKeyMapping = true;
          fonts.packages = [pkgs.nerd-fonts.meslo-lg pkgs.nerd-fonts.gohufont];
          system.defaults.finder.AppleShowAllExtensions = true;
          system.defaults.finder._FXShowPosixPathInTitle = true;
          system.defaults.dock.autohide = true;
          system.defaults.NSGlobalDomain.InitialKeyRepeat = 14;
          system.defaults.NSGlobalDomain.KeyRepeat = 1;
          system.primaryUser = "tauraamui";
          system.stateVersion = 6;
          homebrew = {
            enable = true;
            caskArgs.no_quarantine = true;
          };
        })
        inputs.home-manager.darwinModules.home-manager
        {
          users.users.tauraamui.home = "/Users/tauraamui";
          home-manager = {
            useUserPackages = true;
            users.tauraamui.imports = [
              ({
                pkgs,
                lib,
                ...
              }: {
                # home-manager configs for tauraamui
                home.username = "tauraamui";
                home.homeDirectory = "/Users/tauraamui";
                home.stateVersion = "25.05";
                home.packages = [
                  pkgs.bat
                  pkgs.lazygit
                  pkgs.htop
                  pkgs.gnupg
                  pkgs.pinentry-curses
                  pkgs.gawk
                  pkgs.git
                  pkgs.wget
                  pkgs.vlang
                  pkgs.go
                  pkgs.svu
                  pkgs.gh
                  pkgs.httpie
                  pkgs.go-task
                ];
                home.sessionVariables = {
                  PAGER = "less";
                  EDITOR = "nvim"; # for now
                };
                programs.bat.enable = true;
                programs.bat.config.theme = "TwoDark";
                programs.git.enable = true;
                programs.fish.enable = true;
                programs.alacritty = {
                  enable = true;
                  settings.font.normal.family = "GohuFont 11 Nerd Font Mono";
                  settings.font.size = 11;
                };
                programs.tmux = {
                  enable = true;
                  keyMode = "vi";
                  prefix = "C-w";
                  baseIndex = 1;
                  mouse = true;
                  plugins = with pkgs.tmuxPlugins; [
                    sensible
                    yank
                    {
                      plugin = dracula;
                      extraConfig = ''
                        set -g @dracula-plugins "battery ram-usage cpu-usage time weather"
                        set -g @dracula-show-powerline true
                        set -g @dracula-fixed-location "Oxford"
                        set -g @dracula-show-fahrenheit false
                        set -g @dracula-show-flags true
                        set -g @dracula-show-left-icon smiley
                      '';
                    }
                  ];
                  # extraConfig = ''${builtins.readFile "${self.outPath}/tmux/tmux.conf"}'';
                };

                programs.starship = {
                  enable = true;
                  enableFishIntegration = true;
                  settings = {
                    format = lib.concatStrings [
                      "$username"
                      "$hostname"
                      "$directory"
                      "$git_branch"
                      "$git_state"
                      "$git_status"
                      "$c"
                      "$elixir"
                      "$elm"
                      "$golang"
                      "$haskell"
                      "$java"
                      "$julia"
                      "$nodejs"
                      "$nim"
                      "$rust"
                      "$scala"
                      "$docker_context"
                      "$cmd_duration"
                      "$fill"
                      "$time"
                      "$line_break"
                      "$python"
                      "$character"
                    ];
                    add_newline = false;
                    directory = {
                      style = "#75c5fa";
                      fish_style_pwd_dir_length = 1;
                    };
                    character = {
                      success_symbol = "[❯](purple)";
                      error_symbol = "[❯](red)";
                      vimcmd_symbol = "[❮](green)";
                    };
                    c = {
                      symbol = "";
                      style = "fg:#6EB0D4";
                      format = "'[$symbol ($version) ]($style)'";
                    };
                    docker_context = {
                      symbol = "";
                      style = "fg:#6EB0D4";
                      format = "'[$symbol $context ]($style) $path'";
                    };
                    elixir = {
                      symbol = "";
                      style = "fg:#6EB0D4";
                      format = "'[$symbol ($version) ]($style)'";
                    };
                    elm = {
                      symbol = "";
                      style = "fg:#6EB0D4";
                      format = "'[$symbol ($version) ]($style)'";
                    };
                    git_branch = {
                      format = "[$branch]($style)";
                      style = "bright-black";
                    };
                    git_status = {
                      format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](218) ($ahead_behind$stashed )]($style)";
                      style = "cyan";
                      conflicted = "=";
                      untracked = "⇡";
                      modified = "!";
                      staged = "+";
                      renamed = "»";
                      deleted = "✘";
                      stashed = "≡";
                    };
                    git_state = {
                      format = "\([$state( $progress_current/$progress_total)]($style)\) ";
                      style = "bright-black";
                    };
                    golang = {
                      symbol = "";
                      style = "fg:cyan";
                      format = "[$symbol ($version) ]($style)";
                    };
                    haskell = {
                      symbol = "";
                      style = "fg:#605084";
                      format = "[$symbol ($version) ]($style)";
                    };
                    java = {
                      symbol = "";
                      style = "fg:#da3b33";
                      format = "[$symbol ($version) ]($style)";
                    };
                    julia = {
                      symbol = "";
                      style = "fg:#6c82db";
                      format = "[$symbol ($version) ]($style)";
                    };
                    nodejs = {
                      symbol = "";
                      style = "fg:#95cc48";
                      format = "[$symbol ($version) ]($style)";
                    };
                    nim = {
                      symbol = "";
                      style = "fg:#ddc057";
                      format = "[$symbol ($version) ]($style)";
                    };
                    rust = {
                      symbol = "";
                      style = "fg:#fffeee";
                      format = "[$symbol ($version) ]($style)";
                    };
                    scala = {
                      symbol = "";
                      style = "fg:#cd422d";
                      format = "[$symbol ($version) ]($style)";
                    };
                    cmd_duration = {
                      format = "[$duration ]($style)";
                      style = "yellow";
                    };
                    python = {
                      format = "[$virtualenv]($style) ";
                      style = "bright-black";
                    };
                    time = {
                      disabled = false;
                      time_format = "%T"; # 24 Hour:Minute:Second Format
                      style = "fg:#626167";
                      format = "[$time]($style)";
                    };
                    fill = {
                      symbol = " ";
                    };
                  };
                };
              })
            ];
          };
        }
      ];
    };
  };
}
