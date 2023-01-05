-- Aesthetic
-- pcall catches errors if the plugin doesn't load
local ok, catppuccin = pcall(require, "catppuccin")
if not ok then return end
vim.g.catppuccin_flavour = "macchiato"
catppuccin.setup()
vim.cmd [[colorscheme catppuccin]]

require('me.nvimtree')
require('me.lsp')
require('me.options')
require('me.globals')
require('me.lualine')
require('me.keymap')
require('me.telescope')
