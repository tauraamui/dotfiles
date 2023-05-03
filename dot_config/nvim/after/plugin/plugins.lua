-- This file can be loaded by calling `lua require('plugins')` from your init.vim

-- Only required if you have packer configured as `opt`
vim.cmd [[packadd packer.nvim]]
-- run :PackerCompile
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerCompile
  augroup end
]])

return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'
  use { 'catppuccin/nvim', as = 'catppuccin' }

  -- greeting screen
  use {
    "startup-nvim/startup.nvim",
    requires = {"nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim"},
    config = function()
      require("startup").setup(require("startup.themes.dew"))
    end
  }

  -- color scheme
  use 'EdenEast/nightfox.nvim'
  -- use 'nyoom-engineering/oxocarbon.nvim'

  use { 'christoomey/vim-tmux-navigator', lazy = false }

  -- treesitter
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }
  use { 'nvim-treesitter/playground' }
  use 'williamboman/mason.nvim'

  --Markdown preview
  use 'ellisonleao/glow.nvim'
  use 'simrat39/symbols-outline.nvim'
  -- install without yarn or npm
  use({
    "iamcco/markdown-preview.nvim",
    run = function() vim.fn["mkdp#util#install"]() end,
  })

  -- git line blame visualisation
  use {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup()
    end
  }

  -- terminal toggle
  use {
    'akinsho/toggleterm.nvim',
    tag = '*',
    config = function()
      require('toggleterm').setup()
    end
  }

  -- file tree visualisation
  use {
    'nvim-tree/nvim-tree.lua',
    requires = {
      'nvim-tree/nvim-web-devicons'
    }
  }

  -- indent guide lines
  use "lukas-reineke/indent-blankline.nvim"

  -- autopair brackets
  use {
      "windwp/nvim-autopairs",
      config = function() require("nvim-autopairs").setup {} end
  }

  -- go coverage
  use({
    "andythigpen/nvim-coverage",
    requires = "nvim-lua/plenary.nvim",
    config = function()
      require("coverage").setup()
    end,
  })

  -- go test runner adapter
  use({
    "nvim-neotest/neotest",
    requires = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "antoinemadec/FixCursorHold.nvim",
      "nvim-neotest/neotest-go",
      -- Your other test adapters here
    },
    config = function()
      -- get neotest namespace (api call creates or returns namespace)
      local neotest_ns = vim.api.nvim_create_namespace("neotest")
      vim.diagnostic.config({
        virtual_text = {
          format = function(diagnostic)
            local message =
              diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
            return message
          end,
        },
      }, neotest_ns)
      require("neotest").setup({
        -- your neotest config here
        adapters = {
          require("neotest-go"),
        },
      })
    end,
  })

  -- language packs
  use 'sheerun/vim-polyglot'

  --Nvim motions
  --use {
  -- 'phaazon/hop.nvim',
  --branch = 'v2',
  --requires = {'nvim-lua/plenary.nvim'},
  --config = function()
  -- require'hop'.setup{ keys = 'etovxpqdgfblzhckisuran'}
  --end
  --}

  -- LSP Zero autocomplete
  use {
    'VonHeikemen/lsp-zero.nvim',
    requires = {
      -- LSP Support
      {'neovim/nvim-lspconfig'},
      {'williamboman/mason.nvim'},
      {'williamboman/mason-lspconfig.nvim'},

      -- Autocompletion
      {'hrsh7th/nvim-cmp'},
      {'hrsh7th/cmp-buffer'},
      {'hrsh7th/cmp-path'},
      {'saadparwaiz1/cmp_luasnip'},
      {'hrsh7th/cmp-nvim-lsp'},
      {'hrsh7th/cmp-nvim-lua'},

      -- Snippets
      {'L3MON4D3/LuaSnip'},
      -- Snippet Collection (Optional)
      {'rafamadriz/friendly-snippets'},
    }
  }

  --LSP autocomplete
  --use 'hrsh7th/nvim-cmp'
  --use 'hrsh7th/cmp-nvim-lsp'
 --use 'hrsh7th/cmp-buffer'
 --use 'hrsh7th/cmp-path'
 --use 'L3MON4D3/LuaSnip'
 --use 'saadparwaiz1/cmp_luasnip'
 --use 'neovim/nvim-lspconfig'
 --use 'williamboman/nvim-lsp-installer'

  -- file browsing
  use 'nvim-telescope/telescope-file-browser.nvim'

  -- status line
  use 'feline-nvim/feline.nvim'

  -- haskell
  use 'neovimhaskell/haskell-vim'
  use 'alx741/vim-hindent'

  --debugging
  use 'mfussenegger/nvim-dap'
  use 'leoluz/nvim-dap-go'
  use 'rcarriga/nvim-dap-ui'
  use 'theHamsta/nvim-dap-virtual-text'
  use 'nvim-telescope/telescope-dap.nvim'

  -- grammar checking because I can't english
  use 'rhysd/vim-grammarous'

  -- telescope requirements
  use 'nvim-lua/popup.nvim'
  use 'nvim-lua/plenary.nvim'
  use 'nvim-telescope/telescope.nvim'

  -- telescope
  use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }

 use({
    'glepnir/lspsaga.nvim',
    branch = 'main',
    config = function()
      require('lspsaga').setup({})
    end,
})

  --git diff
  use 'sindrets/diffview.nvim'

  --magit
  use 'TimUntersberger/neogit'

  --todo tracking
  use {
    'folke/todo-comments.nvim',
    requires = 'nvim-lua/plenary.nvim',
    config = function()
      require('todo-comments').setup{}
    end
  }

  --devicons
  use 'kyazdani42/nvim-web-devicons'

  --fullstack dev
  use 'pangloss/vim-javascript' --JS support
  use 'leafgarland/typescript-vim' --TS support
  use 'maxmellon/vim-jsx-pretty' --JS and JSX syntax
  use 'jparise/vim-graphql' --GraphQL syntax
  use 'mattn/emmet-vim'
end)
