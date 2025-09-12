{ config, pkgs, pkgs-unstable, lib, nixgl, ... }:
let
  fingerprintFile = "${config.home.homeDirectory}/.config/nixos/gpg-fingerprint";

  # Define the GPG key generation script directly in home.nix
  gpgKeyGeneratorScript = pkgs.writeShellScript "generate-gpg-key" ''
    set -euo pipefail

    GPG_KEY_ID="adampstringer@protonmail.com"
    GPG_KEY_DIR="$HOME/.gnupg"
    FINGERPRINT_FILE="$HOME/.config/nixos/gpg-fingerprint"

    echo "Ensuring GPG directory exists: $GPG_KEY_DIR"
    mkdir -p "$GPG_KEY_DIR"
    chmod 700 "$GPG_KEY_DIR"

    # Create config directory for fingerprint file
    mkdir -p "$(dirname "$FINGERPRINT_FILE")"

    # Check if fingerprint file exists and key is still valid
    if [[ -f "$FINGERPRINT_FILE" ]]; then
      EXISTING_FINGERPRINT=$(cat "$FINGERPRINT_FILE")
      if "${pkgs.gnupg}/bin/gpg" --list-secret-keys "$EXISTING_FINGERPRINT" > /dev/null 2>&1; then
        echo "GPG key with fingerprint $EXISTING_FINGERPRINT already exists and is valid."
        exit 0
      fi
    fi

    # Check if a key with the specified ID already exists
    if ! "${pkgs.gnupg}/bin/gpg" --list-secret-keys --with-colons "$GPG_KEY_ID" > /dev/null 2>&1; then
      echo "No GPG key found for $GPG_KEY_ID. Generating a new one..."

      BATCH_FILE=$(mktemp)
      cat > "$BATCH_FILE" <<-EOF
        %echo Generating a new GPG key for $GPG_KEY_ID
        Key-Type: EDDSA
        Key-Curve: Ed25519
        Subkey-Type: ECDH
        Subkey-Curve: Curve25519
        Name-Real: tauraamui
        Name-Email: $GPG_KEY_ID
        Expire-Date: 0
        %no-protection
        %commit
        %echo Key generation complete.
    EOF

      # Use --pinentry-mode loopback to avoid pinentry requirement
      "${pkgs.gnupg}/bin/gpg" --batch --pinentry-mode loopback --gen-key "$BATCH_FILE"
      rm "$BATCH_FILE"

      echo "GPG key generated successfully."
    else
      echo "GPG key for $GPG_KEY_ID already exists. Skipping generation."
    fi

    # Extract the fingerprint
    FINGERPRINT=$("${pkgs.gnupg}/bin/gpg" --list-secret-keys --with-colons "$GPG_KEY_ID" \
      | ${pkgs.gawk}/bin/awk -F: '/^fpr:/ { print $10; exit }')

    if [[ -z "$FINGERPRINT" ]]; then
      echo "Error: Could not determine GPG fingerprint for $GPG_KEY_ID."
      exit 1
    fi

    echo "GPG_FINGERPRINT=$FINGERPRINT"
    echo "$FINGERPRINT" > "$FINGERPRINT_FILE"
    echo "Fingerprint saved to $FINGERPRINT_FILE"
  '';

  # Script to update Git config with the correct fingerprint
  updateGitConfigScript = pkgs.writeShellScript "update-git-config" ''
    FINGERPRINT_FILE="$HOME/.config/nixos/gpg-fingerprint"

    if [[ -f "$FINGERPRINT_FILE" ]]; then
      FINGERPRINT=$(cat "$FINGERPRINT_FILE")
      echo "Updating Git signing key to: $FINGERPRINT"
      "${pkgs.git}/bin/git" config --global user.signingkey "$FINGERPRINT"
    else
      echo "No fingerprint file found, skipping Git config update"
    fi
  '';

  # Use a default fingerprint that will be replaced after activation
  gpgSigningKeyFingerprint =
    if builtins.pathExists fingerprintFile
    then builtins.replaceStrings ["\n"] [""] (builtins.readFile fingerprintFile)
    else "0000000000000000000000000000000000000000";
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
    pkgs-unstable.vlang
    pkgs.gitAndTools.gh
  ];

  home.file = { };

  home.sessionVariables = { };

  # Add activation script to generate GPG key
  home.activation.generateGpgKey = config.lib.dag.entryAfter ["writeBoundary"] ''
    echo "Running GPG key generation..."
    ${gpgKeyGeneratorScript}
  '';

  # Add activation script to update Git config after GPG key generation
  home.activation.updateGitConfig = config.lib.dag.entryAfter ["generateGpgKey"] ''
    echo "Updating Git configuration..."
    ${updateGitConfigScript}
  '';

  programs.home-manager.enable = true;
  programs.ripgrep.enable = true;
  programs.rio.enable = true;
  programs.kitty.enable = true;
  # programs.obsidian.enable = true;

  programs.neovim = {
    enable = true;
    plugins = with pkgs.nvimPlugins; [
      telescope
      nvim-lspconfig
      plenary
      telescope-file-browser
    ];
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
    extraConfig = ''
      # smart pane switching with awareness of Vim splits.
      # See: https://github.com/christoomey/vim-tmux-navigator
      is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
          | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?)(diff)?$'"
      bind-key 'h' if-shell "$is_vim" 'send-keys C-w h'  'select-pane -L'
      bind-key 'j' if-shell "$is_vim" 'send-keys C-w j'  'select-pane -D'
      bind-key 'k' if-shell "$is_vim" 'send-keys C-w k'  'select-pane -U'
      bind-key 'l' if-shell "$is_vim" 'send-keys C-w l'  'select-pane -R'
      tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
      if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
          "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
      if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
          "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

      # custom keybinds emulating vim like visual select and yank mode
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      # open split panes within same PWD
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"

      # enable full 256 colour support
      set -ga terminal-overrides ',*256color*:smcup@:rmcup@,xterm*:Tc'
      set -g status-position top
    '';
  };

  programs.ghostty = {
    enable = true;
    package = config.lib.nixGL.wrap pkgs.ghostty;
  };

  programs.wezterm = {
    enable = true;
    package = config.lib.nixGL.wrap pkgs.wezterm;
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
      key = gpgSigningKeyFingerprint;
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
