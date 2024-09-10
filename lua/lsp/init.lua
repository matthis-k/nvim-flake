if not nixCats("lsp.enabled") then
    return
end

require("lz.n").load({
    "lazydev-nvim",
    ft = "lua",
    after = function ()
        require("lazydev").setup({
            library = {
                { path = "luvit-meta/library", words = { "vim%.uv" } },
            },
            integrations = {
                lspconfig = true,
                cmp = false,
                coc = false,
            },
            enabled = function (root_dir)
                return not vim.uv.fs_stat(root_dir .. "/.luarc.json")
            end,
        })
    end,
})

for _, file in ipairs(require("utils").lua_files(vim.fn.stdpath("config") .. "/lua/lsp/server_configurations")) do
    local config = require("lsp.server_configurations." .. file.basename)
    if config then
        require("lspconfig")[file.basename].setup(config)
    end
end

vim.diagnostic.config({
    update_in_insert = true,
    virtual_text = false,
    underline = { severity = { vim.diagnostic.severity.ERROR } },
    severity_sort = true,
    signs = {
        text = vim.iter(require("constants").signs.diagnostics)
            :map(function (sign)
                return sign.text
            end)
            :totable(),
        linehl = {},
        numhl = {},
    },
})

for _, sign in pairs(require("constants").signs.diagnostics) do
    vim.fn.sign_define(sign.name, { text = sign.text, texthl = sign.texthl })
end

local function list_workspace_folders()
    vim.print(vim.lsp.buf.list_workspace_folders())
end

local function toggle_inlay_hints()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end

-- keys are a lsp-method (see `:h lsp-method`)
local capability_keymap_table = {
    ["textDocument/codeAction"] = {
        { "n", "<space>la", vim.lsp.buf.code_action, { silent = true, desc = "Code action" } },
    },
    ["textDocument/declaration*"] = {
        { "n", "gD", vim.lsp.buf.declaration, { silent = true, desc = "Go to declaration" } },
    },
    ["textDocument/definition"] = {
        { "n", "gd", vim.lsp.buf.definition, { silent = true, desc = "Go to definition" } },
    },
    ["textDocument/formatting"] = {
        {
            "n",
            "<space>lf",
            function ()
                vim.lsp.buf.format({ async = true })
            end,
            { silent = true, desc = "Format" },
        },
    },
    ["textDocument/hover"] = {
        { "n", "K", vim.lsp.buf.hover, { silent = true, desc = "Show hover information" } },
    },
    ["textDocument/implementation*"] = {
        { "n", "gI", vim.lsp.buf.implementation, { silent = true, desc = "Go to implementation" } },
    },
    ["textDocument/inlayHint"] = {
        { "n", "<space>li", toggle_inlay_hints, { silent = true, desc = "Toggle inlay hints" } },
    },
    ["textDocument/rangeFormatting"] = {
        {
            "v",
            "<space>lf",
            function ()
                vim.lsp.buf.range_format({ async = true })
            end,
            { silent = true, desc = "Format range" },
        },
    },
    ["textDocument/references"] = {
        { "n", "gr", "<cescope lsp_references<cr>", { silent = true, desc = "Find references" } },
    },
    ["textDocument/rename"] = {
        { "n", "<space>lr", vim.lsp.buf.rename, { silent = true, desc = "Rename symbol" } },
    },
    ["textDocument/typeDefinition*"] = {
        { "n", "<space>lD", vim.lsp.buf.type_definition, { silent = true, desc = "Go to type definition" } },
    },
    ["workspace/workspaceFolders"] = {
        { "n", "<space>lwa", vim.lsp.buf.add_workspace_folder,    { silent = true, desc = "Add folder" } },
        { "n", "<space>lwr", vim.lsp.buf.remove_workspace_folder, { silent = true, desc = "Remove folder" } },
        { "n", "<space>lwl", list_workspace_folders,              { silent = true, desc = "List folders" } },
    },
    always = {
        { "n", "gl",        vim.diagnostic.open_float, { silent = true, desc = "Open diagnostics" } },
        { "n", "<space>lk", vim.diagnostic.goto_prev,  { silent = true, desc = "Go to prev diagnostic" } },
        { "n", "<space>lj", vim.diagnostic.goto_next,  { silent = true, desc = "Go to next diagnostic" } },
    },
}

vim.api.nvim_create_augroup("LspKeymaps", { clear = true })
vim.api.nvim_create_autocmd("LspAttach", {
    group = "LspKeymaps",
    callback = function (ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if not client then
            return
        end
        for method, keymaps in pairs(capability_keymap_table) do
            if method == "always" or client.supports_method(method) then
                for _, keymap in ipairs(keymaps) do
                    local modes, lhs, rhs, opts = keymap[1], keymap[2], keymap[3], keymap[4]
                    opts = opts or {}
                    opts.buffer = true
                    vim.keymap.set(modes, lhs, rhs, opts)
                end
            end
        end
    end,
})
