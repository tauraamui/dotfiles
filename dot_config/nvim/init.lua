-- Aesthetic
-- pcall catches errors if the plugin doesn't load
local present, catppuccin = pcall(require, "catppuccin")
if not present then return end

--catppuccin.setup {
--	flavour = "mocha", -- latte, frappe, macchiato, mocha
--	term_colors = true,
--	transparent_background = false,
--	no_italic = false,
--	no_bold = false,
--	styles = {
--		comments = {},
--		conditionals = {},
--		loops = {},
--		functions = {},
--		keywords = {},
--		strings = {},
--		variables = {},
--		numbers = {},
--		booleans = {},
--		properties = {},
--		types = {},
--	},
--	color_overrides = {
--		mocha = {
--			base = "#000000",
--		},
--	},
--	highlight_overrides = {
--		mocha = function(C)
--			return {
--				TabLineSel = { bg = C.pink },
--				NvimTreeNormal = { bg = C.none },
--				CmpBorder = { fg = C.surface2 },
--				Pmenu = { bg = C.none },
--				NormalFloat = { bg = C.none },
--				TelescopeBorder = { link = "FloatBorder" },
--			}
--		end,
--	},
--}

require("catppuccin").setup {
	term_colors = true,
	transparent_background = false,
	integrations = {
		gitsigns = true,
		neotree = true,
		notify = true,
		treesitter = true,
		treesitter_context = true,
		symbols_outline = true,
		telescope = true,
		lsp_trouble = true,
		which_key = true,
		neotest = true,
		mini = true,
		noice = true,
		mason = true,
		dap = {
			enabled = true,
			enable_ui = true, -- enable nvim-dap-ui
		},
		native_lsp = {
			enabled = true,
			virtual_text = {
				errors = { "italic" },
				hints = { "italic" },
				warnings = { "italic" },
				information = { "italic" },
			},
			underlines = {
				errors = { "underline" },
				hints = { "underline" },
				warnings = { "underline" },
				information = { "underline" },
			},
		},
		navic = {
			enabled = false,
			custom_bg = "NONE",
		},
	},
}

vim.cmd.colorscheme "catppuccin"

require('me.globals')
require('me.nvimtree')
require('me.lsp')
require('me.options')
require('me.lualine')
require('me.keymap')
require('me.telescope')
