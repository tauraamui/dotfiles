local globals = {
    loaded_netrw = 1,
    loaded_netrwPlugin = 1,
    mapleader = ';',
    tmux_navigator_no_mappings = 1,
}
for k, v in pairs(globals) do
    vim.g[k] = v
end

vim.cmd('set nowrap')

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
    completeopt = "noinsert,fuzzy,menu,menuone,popup",
}

for k, v in pairs(options) do
    vim.opt[k] = v
end

-- theme
require("nightfox").setup({
    groups = {
        carbonfox = {
            String         = { fg = "#57d7d9" },
            Identifier     = { fg = "#f55da9" }, -- (preferred) any variable name
            Function       = { fg = "#ff7eb6" }, -- function name (also: methods for classes)
            Operator       = { link = "Function" }, -- "sizeof", "+", "*", etc.
            Keyword        = { link = "Function" }, -- any other keyword
            Exception      = { link = "Function" }, -- try, catch, throw
            Type           = { fg = "#ffffff" }, -- (preferred) int, long, char, etc.
        }
    }
})
vim.cmd.colorscheme "carbonfox"

-- enables hover/virtual dialogs showing lines current errors
vim.diagnostic.config({
    virtual_text = false,
    virtual_lines = true,
})

-- git signs
require('gitsigns').setup()

-- terminal toggle
require('toggleterm').setup()

-- autopairs
require('nvim-autopairs').setup()

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

-- autocomplete
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
        local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
        vim.lsp.completion.enable(true, client.id, args.buf, {autotrigger = true})
    end
})

-- want autocomplete to stay open even when backspacing
vim.api.nvim_create_autocmd("TextChangedI", {
    callback = function()
        local col = vim.fn.col('.')
        local line = vim.fn.getline('.')
        local prev_char = line:sub(col-1, col-1)

        if vim.fn.pumvisible() == 0 and prev_char:match('%w') then
            vim.lsp.completion.get()
        elseif vim.fn.pumvisible() == 1 and prev_char == '' then
            -- Keep menu open after backspace
            vim.lsp.completion.get()
        end
    end
})

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

-- Make Enter select completion item (like Ctrl-y) when popup menu is visible
imap { "<CR>", "pumvisible() ? '<C-y>' : '<CR>'", expr = true }

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
