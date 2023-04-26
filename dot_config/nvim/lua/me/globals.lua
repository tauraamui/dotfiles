local globals = {
    mapleader = ";",
    glow_binary_path = vim.env.HOME .. "/bin",
    glow_use_pager = true,
    glow_border = "shadow",
    loaded_netrw = 1,
    loaded_netrwPlugin = 1,
    tmux_navigator_no_mappings = 1,
}

for k, v in pairs(globals) do
	vim.g[k] = v
end

vim.cmd('set nowrap')

