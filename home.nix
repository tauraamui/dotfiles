{ config, pkgs, lib, ... }:
let
  crush = pkgs.buildGoModule rec {
    pname = "crush";
    version = "0.24.0";

    src = pkgs.fetchFromGitHub {
      owner = "charmbracelet";
      repo = "crush";
      rev = "v${version}";
      sha256 = "sha256-UcaWSMBVjIaGG9AhdJtzHCWkkVpzmhN9PPsmeDCxvi4=";
    };

    vendorHash = "sha256-eKiDfdZqpB2+j4S3KcOswnFum3yPSdPzxp1A80DnxQg=";
    doCheck = false;
  };

  invoice = pkgs.buildGoModule {
    pname = "invoice";
    version = "0.1.0";

    src = pkgs.fetchFromGitHub {
      owner = "maaslalani";
      repo = "invoice";
      rev = "main";
      sha256 = "sha256-nHTwNdc6IvKRYZGeU3PHDb++brgs0YR34GgQFue3+FE=";
    };

    vendorHash = "sha256-mLn9hN7hd3MPYx0STiwCL8pTTYtDlycVkSLUEq8NZOE=";
    doCheck = false;
  };
in
{
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
    pkgs.go
    pkgs.svu
    pkgs.gh
    pkgs.httpie
    pkgs.go-task
    # go tools + packages
    crush
    pkgs.gotools
    pkgs.gotestsum
    pkgs.gofumpt
    pkgs.sqlc
    pkgs.scc
    invoice
  ];

  home.sessionVariables = {
    PAGER = "less";
    EDITOR = "nvim";
  };

  programs.home-manager.enable = true;
  programs.ripgrep.enable = true;
  programs.gh-dash.enable = true;

  programs.bat = {
    enable = true;
    config.theme = "TwoDark";
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        email = "adampstringer@protonmail.com";
        name = "tauraamui";
      };
      url = {
        "ssh://git@github.com/" = {
          insteadOf = "https://github.com/";
        };
      };
    };
    signing = {
      format = "ssh";
      key = "/Users/tauraamui/.ssh/id_ed25519.pub";
      signByDefault = true;
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

  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      auto_sync = true;
      sync_frequency = "10m";
      sync_address = "https://api.atuin.sh";
      search_mode = "fuzzy";
    };
  };

  programs.autojump = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.neovim = {
    enable = true;
    extraLuaConfig = ''${builtins.readFile ./nvim/init.lua}'';
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

  programs.alacritty = {
    enable = true;
    settings.terminal.shell.program = "/etc/profiles/per-user/tauraamui/bin/fish";
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
    extraConfig = ''${builtins.readFile ./tmux/tmux.conf}'';
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
        symbol = "";
        style = "fg:#6EB0D4";
        format = "'[$symbol ($version) ]($style)'";
      };
      docker_context = {
        symbol = "";
        style = "fg:#6EB0D4";
        format = "'[$symbol $context ]($style) $path'";
      };
      elixir = {
        symbol = "";
        style = "fg:#6EB0D4";
        format = "'[$symbol ($version) ]($style)'";
      };
      elm = {
        symbol = "";
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
        symbol = "";
        style = "fg:cyan";
        format = "[$symbol ($version) ]($style)";
      };
      haskell = {
        symbol = "";
        style = "fg:#605084";
        format = "[$symbol ($version) ]($style)";
      };
      java = {
        symbol = "";
        style = "fg:#da3b33";
        format = "[$symbol ($version) ]($style)";
      };
      julia = {
        symbol = "";
        style = "fg:#6c82db";
        format = "[$symbol ($version) ]($style)";
      };
      nodejs = {
        symbol = "";
        style = "fg:#95cc48";
        format = "[$symbol ($version) ]($style)";
      };
      nim = {
        symbol = "";
        style = "fg:#ddc057";
        format = "[$symbol ($version) ]($style)";
      };
      rust = {
        symbol = "";
        style = "fg:#fffeee";
        format = "[$symbol ($version) ]($style)";
      };
      scala = {
        symbol = "";
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

  programs.fish = {
    enable = true;

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

    interactiveShellInit = ''
      set -g fish_greeting ""
      fish_add_path ~/.local/bin
      set -gx SHELL /etc/profiles/per-user/tauraamui/bin/fish
    '';

    loginShellInit = ''
      if test -e ~/.nix-profile/etc/profile.d/nix.fish
        source ~/.nix-profile/etc/profile.d/nix.fish
      end
      if test -e ~/.nix-profile/etc/profile.d/hm-session-vars.sh
        bass source ~/.nix-profile/etc/profile.d/hm-session-vars.sh
      end
    '';

    shellAliases = {
      au  = "atuin";
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

    functions = {
      mkcd = "mkdir -p $argv[1]; and cd $argv[1]";
    };
  };
}
