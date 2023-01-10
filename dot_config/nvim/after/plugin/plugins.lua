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

  --Treesitter
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }
  use 'williamboman/mason.nvim'

  --Markdown preview
  use 'ellisonleao/glow.nvim'
  use 'simrat39/symbols-outline.nvim'
  -- install without yarn or npm
  use({
    "iamcco/markdown-preview.nvim",
    run = function() vim.fn["mkdp#util#install"]() end,
  })

  -- File tree visualisation
  use {
    'nvim-tree/nvim-tree.lua',
    requires = {
      'nvim-tree/nvim-web-devicons'
    }
  }

  -- Indent guide lines
  use "lukas-reineke/indent-blankline.nvim"

  -- Go coverage
  use({
    "andythigpen/nvim-coverage",
    requires = "nvim-lua/plenary.nvim",
    config = function()
      require("coverage").setup()
    end,
  })

  -- Go test runner adapter
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

  --Language packs
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

  --File browsing
  use 'nvim-telescope/telescope-file-browser.nvim'

  --Buffer navigation
  use 'nvim-lualine/lualine.nvim'

  --Haskell
  use 'neovimhaskell/haskell-vim'
  use 'alx741/vim-hindent'

  --debugging
  use 'mfussenegger/nvim-dap'
  use 'leoluz/nvim-dap-go'
  use 'rcarriga/nvim-dap-ui'
  use 'theHamsta/nvim-dap-virtual-text'
  use 'nvim-telescope/telescope-dap.nvim'

  --Grammar checking because I can't english
  use 'rhysd/vim-grammarous'

  --Telescope Requirements
  use 'nvim-lua/popup.nvim'
  use 'nvim-lua/plenary.nvim'
  use 'nvim-telescope/telescope.nvim'

  --Telescope
  use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }

  --git diff
  use 'sindrets/diffview.nvim'

  --magit
  use 'TimUntersberger/neogit'

  --todo comments
  use 'folke/todo-comments.nvim'

  --devicons
  use 'kyazdani42/nvim-web-devicons'

  --fullstack dev
  use 'pangloss/vim-javascript' --JS support
  use 'leafgarland/typescript-vim' --TS support
  use 'maxmellon/vim-jsx-pretty' --JS and JSX syntax
  use 'jparise/vim-graphql' --GraphQL syntax
  use 'mattn/emmet-vim'
end)
