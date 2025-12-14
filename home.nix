{ self, config, pkgs, pkgs-unstable, lib, nixgl, ... }:
let
  crush = pkgs-unstable.buildGoModule rec {
    pname = "crush";
    version = "0.24.0";

    src = pkgs.fetchFromGitHub {
      owner = "charmbracelet";
      repo = "crush";
      rev = "v${version}";
      sha256 = "sha256-5L1O/xJQPSKr5XF2kJn8Nb44WJBOOshjZW6Dl529/ls=";
    };

    # lib.fakeHash to derive correct hash to use
    vendorHash = lib.fakeHash; # Update me;
    # crush attempts to download provider data on build/test, so prevent the tests
    # from failing due to being able to resolve this data
    doCheck = false;
  };

  gofumpt = pkgs-unstable.buildGoModule {
    pname = "gofumpt";
    version = "latest";

    src = pkgs.fetchFromGitHub {
      owner = "mvdan";
      repo = "gofumpt";
      rev = "718975501de6321ddf0a5fd17b4f959d33fa203e";
      sha256 = "sha256-ngqg8YJHqW08hvZp+E+RLLjGArOZJov7/xKCMAWFI1E=";
    };

    vendorHash = lib.fakeHash; # Update me;
    doCheck = false;
  };

  goimports = pkgs-unstable.buildGoModule {
    pname = "goimports";
    version = "latest";

    src = pkgs.fetchFromGitHub {
      owner = "golang";
      repo = "tools";
      rev = "1f3446a1f9bc9e1f88c289b7ee852d29a1452c10";
      sha256 = "sha256-094vk5rknJw68pZ8ZsGvxdVfkDIr/QG61xKAYsdW0vA=";
    };

    vendorHash = lib.fakeHash; # Update me;
    doCheck = false;
    subPackages = [ "cmd/goimports" ];
  };

  scc = pkgs-unstable.buildGoModule {
    pname = "scc";
    version = "latest";

    src = pkgs.fetchFromGitHub {
      owner = "boyter";
      repo = "scc";
      rev = "a05061505b9313b62468fd44510f920b07fdff1c";
      sha256 = "sha256-NsJ6WtqkXAXUAJEKoAhsuR+xSEzTEsDzEAqBTrpRsCA=";
    };

    vendorHash = lib.fakeHash; # Update me;
    doCheck = false;
  };

  sqlc = pkgs-unstable.buildGoModule {
    pname = "sqlc";
    version = "latest";

    src = pkgs.fetchFromGitHub {
      owner = "sqlc-dev";
      repo = "sqlc";
      rev = "74ecda5fa1cc2bd7e237584ef18e43a14e6d7f81";
      sha256 = "sha256-AfdUMu/dshw3G+oNoQ4BxFNBzIsKGD0a3wn6pfisOqk=";
    };

    vendorHash = lib.fakeHash; # Update me;
    doCheck = false;
    subPackages = [ "cmd/sqlc" ];
  };

  gotestsum = pkgs-unstable.buildGoModule {
    pname = "gotestsum";
    version = "latest";

    src = pkgs.fetchFromGitHub {
      owner = "gotestyourself";
      repo = "gotestsum";
      rev = "06f60b3249917ddd1a04c8e2586116d1a87bc67c";
      sha256 = "sha256-bChELLxindXJ2lFfzOu3x2ZXDudAheo2n9S5x87w+Mc=";
    };

    vendorHash = lib.fakeHash; # Update me;
    doCheck = false;
  };

  invoice = pkgs-unstable.buildGoModule {
    pname = "invoice";
    version = "latest";

    src = pkgs.fetchFromGitHub {
      owner = "maaslalani";
      repo = "invoice";
      rev = "0fb2e9d84385c6393ca6925bc6d25a89555b0b2d";
      sha256 = "sha256-nHTwNdc6IvKRYZGeU3PHDb++brgs0YR34GgQFue3+FE=";
    };

    vendorHash = lib.fakeHash; # Update me;
    doCheck = false;
  };
in
{
  home.username = "tauraamui";
  home.homeDirectory = "/home/tauraamui";
  home.stateVersion = "25.05";

  nixpkgs.config.allowUnfree = true;

  # Conditionally include XDG config only for penguin hostname
  xdg = lib.optionalAttrs (builtins.pathExists "/etc/hostname" &&
                           lib.hasInfix "penguin" (builtins.readFile "/etc/hostname")) {
    configFile."systemd/user/cros-garcon.service.d/override.conf".text = ''
      [Service]
      Environment="PATH=%h/.nix-profile/bin:/usr/local/sbin:/usr/local/bin:/usr/local/games:/usr/sbin:/usr/bin:/usr/games:/sbin:/bin"
      Environment="XDG_DATA_DIRS=%h/.nix-profile/share:%h/.local/share:%h/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share"
    '';
  };

  nixGL.packages = nixgl.packages;
  nixGL.defaultWrapper = "mesa";

  home.packages = [
    pkgs.lazygit
    pkgs.htop
    pkgs.gnupg
    pkgs.pinentry-curses
    pkgs.gawk
    pkgs.git
    pkgs.wget
    pkgs.xdotool
    pkgs-unstable.vlang
    pkgs-unstable.go
    pkgs-unstable.svu
    pkgs.gitAndTools.gh
    pkgs.httpie
    pkgs.go-task
    # go tools + packages
    crush
    goimports
    gotestsum
    gofumpt
    sqlc
    scc
    invoice
  ];

  home.file = {
    ".XCompose".source = ./compose-mappings;
    ".config/hypr/bindings.conf".source = ./hypr/bindings.conf;
    ".config/hypr/hyprlock.conf".source = ./hypr/hyprlock.conf;
    ".config/hypr/looknfeel.conf".source = ./hypr/looknfeel.conf;
    ".config/waybar/config.jsonc".source = ./waybar/config.jsonc;
  };

  home.sessionVariables = { };

  programs.home-manager.enable = true;
  programs.ripgrep.enable = true;
  programs.rio.enable = true;
  programs.kitty.enable = true;
  programs.gh-dash.enable = true; # bit confused how this works since `gh` itself is installed a package not a program but oki
  # programs.obsidian.enable = true;

  programs.neovim = {
    enable = true;
    extraLuaConfig = ''${builtins.readFile "${self.outPath}/nvim/init.lua"}'';
    plugins = with pkgs.nvimPlugins; [
      gitsigns
      nightfox-theme
      nvim-autopairs
      nvim-goc
      nvim-lspconfig
      nvim-treesitter
      nvim-tree
      nvim-web-devicons
      plenary
      pkgs.vimPlugins.lazy-lsp-nvim
      startup
      telescope
      telescope-file-browser
      toggleterm
      trouble
      vim-tmux-navigator
    ];

    extraConfig = ''
        lua << EOF
        require('lazy-lsp').setup {}
        EOF
    '';
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
    extraConfig = ''${builtins.readFile "${self.outPath}/tmux/tmux.conf"}'';
  };

  programs.ghostty = {
    enable = true;
    package = config.lib.nixGL.wrap pkgs.ghostty;
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

  programs.autojump = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.git = {
    enable = true;
    userEmail = "adampstringer@protonmail.com";
    userName = "tauraamui";
    signing = {
      format = "ssh";
      key = "/home/tauraamui/.ssh/id_ed25519.pub";
      signByDefault = true;
    };
    extraConfig = {
      url = {
        "ssh://git@github.com/" = {
          insteadOf = "https://github.com/";
        };
      };
    };
  };

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
    };
    gitCredentialHelper = {
      enable = true;
    };
  };

  # Enable and configure Fish shell
  programs.fish = {
    enable = true;

    # Fish plugins
    plugins = [
      {
        name = "bass";
        src = pkgs.fetchFromGitHub {
          owner = "edc";
          repo = "bass";
          rev = "2fd3d2157d5271ca3575b13daec975ca4c10577a";
          sha256 = "0mb01y1d0g8ilsr5m8a71j6xmqlyhf8w4xjf00wkk8k41cz3ypky";
        };
      }
    ];

    # Optional: Add custom configuration
    interactiveShellInit = ''
      # Custom Fish configuration goes here
      set -g fish_greeting ""  # Disable greeting message
      set -g LD_LIBRARY_PATH "/usr/lib"
      fish_add_path ~/.local/bin
    '';

    # Ensure Nix environment is loaded
    loginShellInit = ''
      # Source Nix environment
      if test -e ~/.nix-profile/etc/profile.d/nix.fish
        source ~/.nix-profile/etc/profile.d/nix.fish
      end
      if test -e ~/.nix-profile/etc/profile.d/hm-session-vars.sh
        bass source ~/.nix-profile/etc/profile.d/hm-session-vars.sh
      end
    '';

    # Optional: Add shell aliases
    shellAliases = {
      gob = "go build .";
      gof = "go fmt -x ./...";
      goi = "goimports -w .";
      gor = "go run ./...";
      gos = "gotestsum ./...";
      got = "go test ./...";
      gotx = "go test -count=1 ./...";
      vt = "./make.vsh test";
      gc = "git checkout";
      gb = "git branch";
      gp = "git remote prune origin";
      ll = "ls -la";
      la = "ls -la";
      l = "ls -l";
      ".." = "cd ..";
      "..." = "cd ../..";
    };

    # Optional: Add functions
    functions = {
      # Example function
      mkcd = "mkdir -p $argv[1]; and cd $argv[1]";
    };
  };
}
