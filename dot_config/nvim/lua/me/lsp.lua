-- Native LSP Setup
require("me.keymap")
-- Global setup.
local cmp = require'cmp'
cmp.setup({
  snippet = {
     expand = function(args)
       require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
     end,
  },
  mapping = {
    ['<Up>'] = function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      else
        fallback()
      end
    end,
    ['<Down>'] = function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      else
        fallback()
      end
    end,
    ['<Tab>'] = function(fallback)
      if cmp.visible() then
        cmp.confirm()
      else
        fallback()
      end
    end,
    ['<CR>'] = function(fallback)
      if cmp.visible() then
        cmp.confirm()
      else
        fallback()
      end
    end
  },

  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' }, -- For luasnip users.
  }, {
    { name = 'buffer' },
  })
})

local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
-- local lsp_installer = require("nvim-lsp-installer")
-- lsp_installer.settings({
--     ui = {
--         icons = {
--             server_installed = "✓",
--             server_pending = "➜",
--             server_uninstalled = "✗"
--         }
--     }
-- })

local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())
local on_attach = function(client, bufnr)

    local function buf_set_keymap(...)
        vim.api.nvim_buf_set_keymap(bufnr, ...)
    end

    -- Mappings.
    local opts = { noremap = true, silent = true }

    -- See `:help vim.lsp.*` for documentation on any of the below functions
    -- leaving only what I actually use...
    vim.cmd([[
        augroup formatting
            autocmd! * <buffer>
            autocmd BufWritePre <buffer> lua vim.lsp.buf.format()
            autocmd BufWritePre <buffer> lua OrganizeImports(1000)
        augroup END
    ]])

-- Set autocommands conditional on server_capabilities
    vim.cmd([[
        augroup lsp_document_highlight
            autocmd! * <buffer>
            autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
            autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
        augroup END
    ]])
end

-- organize imports
-- https://github.com/neovim/nvim-lspconfig/issues/115#issuecomment-902680058
function OrganizeImports(timeoutms)
    local params = vim.lsp.util.make_range_params()
    params.context = { only = { "source.organizeImports" } }
    local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, timeoutms)
    for _, res in pairs(result or {}) do
        for _, r in pairs(res.result or {}) do
            if r.edit then
                vim.lsp.util.apply_workspace_edit(r.edit, "UTF-8")
            else
                vim.lsp.buf.execute_command(r.command)
            end
        end
    end
end

local lsp = require('lsp-zero').preset({})
lsp.ensure_installed({
  'gopls',
})
lsp.setup()

local util = require 'lspconfig.util'
local lsp_configurations = require('lspconfig.configs')
if not lsp_configurations.v_analyzer then
  lsp_configurations.v_analyzer = {
    default_config = {
      name = 'v-analyzer',
      cmd = {'v-analyzer'},
      filetypes = {'vlang', 'v', 'vsh', 'vv'},
      root_dir = util.root_pattern('v.mod', '.git'),
    }
  }
end

local lspconfig = require('lspconfig')
-- Go LSP
lspconfig.gopls.setup {
    capabilities = capabilities,
    on_attach = on_attach,
    settings = {
        gopls = {
            gofumpt = false,
        },
    },
    flags = {
        debounce_text_changes = 150,
    },
}

lspconfig.v_analyzer.setup({})
vim.cmd([[au BufNewFile,BufRead *.v set filetype=vlang]])


-- lspconfig.golangci_lint_ls.setup {
--   capabilities = capabilities,
--   on_attach = on_attach,
--   settings = {
--     gopls = {
--       gofumpt = false,
--     },
--   },
--   flags = {
--     debounce_text_changes = 150,
--   },
-- }
