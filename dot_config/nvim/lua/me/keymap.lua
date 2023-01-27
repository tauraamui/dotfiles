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


local ok, treesitter = pcall(require, "nvim-treesitter.configs")
if not ok then return end
treesitter.setup { ensure_installed = "all", highlight = { enable = true } }

-- keymaps
vim.keymap.set("n", "<leader>p", "<cmd>Glow<cr>")
nmap{"<leader>ff", "<cmd>Telescope find_files<cr>"}
nmap{"<leader>fc", "<cmd>Telescope current_buffer_fuzzy_find<cr>"}
nmap{"<leader>fg", "<cmd>Telescope live_grep<cr>"}
nmap{"<leader>fd", "<cmd>Telescope diagnostics<cr>"}
nmap{"<leader>fb", "<cmd>Telescope buffers<cr>"}
nmap{"<leader>fr", "<cmd>Telescope lsp_references<cr>"}
nmap{"<leader>ft", "<cmd>TodoQuickFix<cr>"}
nmap{"<leader>gb", "<cmd>Gitsigns blame_line<cr>"}


nmap{"<leader>tt", "<cmd>NvimTreeToggle<cr>"}
nmap{"<leader>tcf", ":lua require'neotest'.run.run()<CR>"}
nmap{"<leader>tcw", ":lua require'neotest'.run.run(vim.fn.getcwd())<CR>"}
nmap{"<leader>tsw", ":lua require'neotest'.summary.open()<CR>"}

