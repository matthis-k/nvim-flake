require("lz.n").load({
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdLineEnter" },
    after = function ()
        local cmp = require("cmp")
        cmp.setup({
            completion = {
                winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
                completeopt = "menu,menuone,noinsert,noselect",
            },
            preselect = "None",
            mapping = {
                ["<c-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
                ["<c-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
                ["<c-b>"] = cmp.mapping.scroll_docs(-4),
                ["<c-f>"] = cmp.mapping.scroll_docs(4),
                ["<c-space>"] = cmp.mapping.complete(),
                ["<c-e>"] = cmp.mapping.abort(),
                ["<cr>"] = cmp.mapping({
                    i = function (fallback)
                        if cmp.visible() and cmp.get_active_entry() then
                            cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
                        else
                            fallback()
                        end
                    end,
                    s = cmp.mapping.confirm({ select = true }),
                    c = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false }),
                }),
            },
            sources = cmp.config.sources({
                { name = "nvim_lsp" },
                { name = "path" },
            }, {
                { name = "buffer" },
            }),
            formatting = {
                fields = { "kind", "abbr", "menu" },
                format = function (entry, vim_item)
                    local kind = require("lspkind").cmp_format({ mode = "symbol_text", maxwidth = 50 })(entry, vim_item)
                    local strings = vim.split(kind.kind, "%s", { trimempty = true })
                    kind.kind = " " .. (strings[1] or "") .. " "
                    kind.menu = "    (" .. (strings[2] or "") .. ")"
                    return kind
                end,
            },
            experimental = {
                ghost_text = {
                    hl_group = "LspCodeLens",
                },
            },
        })
        cmp.setup.cmdline({ "/", "?" }, {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {
                { name = "buffer" },
            },
        })

        -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
        cmp.setup.cmdline(":", {
            mapping = cmp.mapping.preset.cmdline(),
            sources = cmp.config.sources({
                { name = "path" },
            }, {
                { name = "cmdline" },
            }),
        })
    end,
})
