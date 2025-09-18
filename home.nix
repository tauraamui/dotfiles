{ config, pkgs, pkgs-unstable, lib, nixgl, ... }:
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
    pkgs-unstable.go
    pkgs.gitAndTools.gh
  ];

  home.file = { };

  home.sessionVariables = { };

  programs.home-manager.enable = true;
  programs.ripgrep.enable = true;
  programs.rio.enable = true;
  programs.kitty.enable = true;
  # programs.obsidian.enable = true;

  programs.neovim = {
    enable = true;
    extraLuaConfig = ''
      local globals = {
        loaded_netrw = 1,
        loaded_netrwPlugin = 1,
        mapleader = ';',
        tmux_navigator_no_mappings = 1,
      }
      for k, v in pairs(globals) do
        vim.g[k] = v
      end

      local options = {
        ma = true,
        mouse = "a",
        cursorline = true,
        tabstop = 4,
        shiftwidth = 4,
        softtabstop = 4,
        expandtab = true,
        autoread = true,
        nu = true,
        foldlevelstart = 99,
        scrolloff = 7,
        backup = false,
        writebackup = false,
        swapfile = false,
        clipboard = "unnamedplus",
        ignorecase = true,
        smartcase = true,
        termguicolors = true,
      }
      for k, v in pairs(options) do
        vim.opt[k] = v
      end


      -- file in focus show relative line nums, when not show non-relative
      local augroup = vim.api.nvim_create_augroup("numbertoggle", {})

      vim.api.nvim_create_autocmd({ "BufEnter", "FocusGained", "InsertLeave", "WinEnter" }, {
        pattern = "*",
        group = augroup,
        callback = function()
           if vim.o.nu and vim.api.nvim_get_mode().mode ~= "i" then
              vim.opt.relativenumber = true
           end
        end,
      })

      -- swap relative line numbers toggle on enter
      vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost", "InsertEnter", "WinLeave" }, {
        pattern = "*",
        group = augroup,
        callback = function()
           if vim.o.nu then
              vim.opt.relativenumber = false
              vim.cmd "redraw"
           end
        end,
      })

      vim.cmd('set nowrap')

      -- nvim tree setup

      require('nvim-tree').setup()
      
      local function open_nvim_tree(data)
        -- buffer is a directory
        local directory = vim.fn.isdirectory(data.file) == 1
        if not directory then
            return
        end
        
        -- change to the directory
        vim.cmd.cd(data.file)
        
        -- open the tree
        require('nvim-tree.api').tree.open()
      end
      
      vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })

      -- keybinds
      local keymap = function(tbl)
        local opts = { noremap = true, silent = true }
        local mode = tbl['mode']
        tbl['mode'] = nil
        local bufnr = tbl['bufnr']
        tbl['bufnr'] = nil
        
        for k, v in pairs(tbl) do
        	if tonumber(k) == nil then
        		opts[k] = v
        	end
        end
        
        if bufnr ~= nil then
        	vim.api.nvim_buf_set_keymap(bufnr, mode, tbl[1], tbl[2], opts)
        else
        	vim.api.nvim_set_keymap(mode, tbl[1], tbl[2], opts)
        end
      end
      
      nmap = function(tbl)
        tbl['mode'] = 'n'
        keymap(tbl)
      end
      
      imap = function(tbl)
        tbl['mode'] = 'i'
        keymap(tbl)
      end

      -- tmux-navigator keybinds
      nmap { "<C-w>h", "<cmd>TmuxNavigateLeft<cr>" }
      nmap { "<C-w>j", "<cmd>TmuxNavigateDown<cr>" }
      nmap { "<C-w>k", "<cmd>TmuxNavigateUp<cr>" }
      nmap { "<C-w>l", "<cmd>TmuxNavigateRight<cr>" }

      -- telescope keybinds
      nmap{ "<leader>ff", "<cmd>Telescope find_files<cr>" }
      nmap{ "<leader>fc", "<cmd>Telescope current_buffer_fuzzy_find<cr>" }
      nmap{ "<leader>fg", "<cmd>Telescope live_grep<cr>" }
      nmap{ "<leader>fd", "<cmd>Telescope diagnostics<cr>" }
      nmap{ "<leader>fo", "<cmd>Telescope oldfiles<cr>" }
      nmap{ "<leader>fb", "<cmd>Telescope buffers<cr>" }
      nmap{ "<leader>fv", "<cmd>Telescope file_browser<cr>" }
      nmap{ "<leader>fr", "<cmd>Telescope lsp_references<cr>" }
      nmap{ "<leader>ft", "<cmd>TodoTelescope<cr>" }
      nmap{ "<leader>gb", "<cmd>Gitsigns blame_line<cr>" }

      -- nvim-tree keybind
      nmap{ "<leader>tt", "<cmd>NvimTreeToggle<cr>" }
    '';
    plugins = with pkgs.nvimPlugins; [
      telescope
      nvim-lspconfig
      nvim-treesitter
      nvim-tree
      plenary
      telescope-file-browser
      vim-tmux-navigator
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

      set -g default-shell "~/.nix-profile/bin/fish"
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
      gc = "git checkout";
      gb = "git branch";
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
