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
            debug = false,
            runtime = vim.env.VIMRUNTIME,
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

for _, file in ipairs(require("utils").lua_files(nixCats.configDir .. "/lsp")) do
    vim.lsp.enable(file.basename, true)
end

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
