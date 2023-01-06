local globals = {
    glow_binary_path = vim.env.HOME .. "/bin",
    glow_use_pager = true,
    glow_border = "shadow",
    loaded_netrw = 1,
    loaded_netrwPlugin = 1,
}

for k, v in pairs(globals) do
	vim.g[k] = v
end
