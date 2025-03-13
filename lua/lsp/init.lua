if not nixCats("lsp.enabled") then
    return
end

require("lz.n").load({
    "conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo", "FormatOff", "FormatOn" },
    keys = {
        { "<leader>vf", "<cmd>FormatOn<cr>",  mode = "n", silent = true, desc = "Re-enable autoformat-on-save" },
        { "<leader>vF", "<cmd>FormatOff<cr>", mode = "n", silent = true, desc = "Disable autoformat-on-save" },
        { "<leader>l",  "<nop>",              mode = "n", silent = true, desc = "Lsp" },
        {
            "<leader>lf",
            function ()
                require("conform").format({ async = true })
            end,
            mode = "n",
            silent = true,
            desc = "Format buffer",
        },
        {
            "<space>lf",
            function ()
                require("conform").format({
                    async = true,
                    range = {
                        start = vim.api.nvim_buf_get_mark(0, "<"),
                        ["end"] = vim.api.nvim_buf_get_mark(0, ">"),
                    },
                })
            end,
            mode = "v",
            silent = true,
            desc = "Format range",
        },
    },
    after = function ()
        require("conform").setup({
            default_format_opts = {
                lsp_format = "prefer",
            },
            format_on_save = function (bufnr)
                if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                    return
                end
                return { timeout_ms = 500 }
            end,
        })

        vim.api.nvim_create_user_command("FormatOff", function (args)
            if args.bang then
                vim.b.disable_autoformat = true
            else
                vim.g.disable_autoformat = true
            end
        end, {
            desc = "Disable autoformat-on-save",
            bang = true,
        })
        vim.api.nvim_create_user_command("FormatOn", function ()
            vim.b.disable_autoformat = false
            vim.g.disable_autoformat = false
        end, {
            desc = "Re-enable autoformat-on-save",
        })
    end,
})

require("lz.n").load({
    "lazydev.nvim",
    cmd = "LazyDev",
    ft = "lua",
    after = function ()
        require("lazydev").setup({
            library = {
                { words = { "nixCats" },       path = (require("nixCats").nixCatsPath or "") .. "/lua" },
                { path = "luvit-meta/library", words = { "vim%.uv" } },
            },
            integrations = {
                lspconfig = false,
                cmp = false,
                coc = false,
            },
            enabled = function (root_dir)
                return not vim.uv.fs_stat(root_dir .. "/.luarc.json")
            end,
        })
    end,
})
require("lz.n").load({
    "nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    after = function ()
        for _, file in ipairs(require("utils").lua_files(nixCats.configDir .. "/lua/lsp/server_configurations")) do
            local config = require("lsp.server_configurations." .. file.basename)
            if config and type(config) == "table" then
                require("lspconfig")[file.basename].setup(config)
            end
        end
    end,
})

vim.diagnostic.config({
    update_in_insert = true,
    virtual_text = false,
    underline = { severity = { vim.diagnostic.severity.ERROR } },
    severity_sort = true,
    signs = {
        text = vim.tbl_map(function (sign) return sign.text end, require("constants").signs.diagnostics),
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

local border = require("constants").wins.border
local function with_border(fn)
    return function ()
        fn({ border = border })
    end
end

-- keys are a lsp-method (see `:h lsp-method`)
local capability_keymap_table = {
    ["textDocument/codeAction"] = {
        { "n", "gra", with_border(vim.lsp.buf.code_action), { silent = true, desc = "Code action" } },
    },
    ["textDocument/declaration*"] = {
        { "n", "gD", vim.lsp.buf.declaration, { silent = true, desc = "Go to declaration" } },
    },
    ["textDocument/definition"] = {
        { "n", "gd", nixCats("telescope.enabled") and "<cmd>Telescope lsp_definitions<cr>"
        or vim.lsp.buf.definition, { silent = true, desc = "Go to definition" } },
    },
    ["textDocument/formatting"] = {
        -- handled by conform
    },
    ["textDocument/hover"] = {
        { "n", "K", with_border(vim.lsp.buf.hover), { silent = true, desc = "Show hover information" } },
    },
    ["textDocument/implementation*"] = {
        { "n", "gri", nixCats("telescope.enabled") and "<cmd>Telescope lsp_implementations<cr>"
        or vim.lsp.buf.implementation, { silent = true, desc = "Go to implementation" } },
    },
    ["textDocument/inlayHint"] = {
        { "n", "<space>li", toggle_inlay_hints, { silent = true, desc = "Toggle inlay hints" } },
    },
    ["textDocument/rangeFormatting"] = {
    },
    ["textDocument/references"] = {
        { "n", "grr", nixCats("telescope.enabled") and "<cmd>Telescope lsp_references<cr>"
        or vim.lsp.buf.references, { silent = true, desc = "Find references" } },
    },
    ["textDocument/rename"] = {
        { "n", "grn", vim.lsp.buf.rename, { silent = true, desc = "Rename symbol" } },
    },
    ["textDocument/typeDefinition*"] = {
        { "n", "grd", nixCats("telescope.enabled") and "<cmd>Telescope lsp_type_definitions<cr>"
        or vim.lsp.buf.type_definition, { silent = true, desc = "Go to type definition" } },
    },
    ["workspace/workspaceFolders"] = {
        { "n", "<leader>lw", "<nop>",                             { desc = "Workspace" } },
        { "n", "<space>lwa", vim.lsp.buf.add_workspace_folder,    { silent = true, desc = "Add folder" } },
        { "n", "<space>lwr", vim.lsp.buf.remove_workspace_folder, { silent = true, desc = "Remove folder" } },
        { "n", "<space>lwl", list_workspace_folders,              { silent = true, desc = "List folders" } },
    },
    always = {
        { "n", "<leader>l", "<nop>",                                             { desc = "Lsp" } },
        { "n", "gl",        with_border(vim.diagnostic.open_float),              { silent = true, desc = "Open diagnostics" } },
        { "n", "<space>lk", function () vim.diagnostic.jump({ count = -1 }) end, { silent = true, desc = "Go to prev diagnostic" } },
        { "n", "<space>lj", function () vim.diagnostic.jump({ count = 1 }) end,  { silent = true, desc = "Go to next diagnostic" } },
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
            if method == "always" or client:supports_method(method) then
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
