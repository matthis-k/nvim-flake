if not nixCats("completion.enabled") then
    return
end

local constants = require("constants")

require("blink.cmp").setup({
    keymap = {
        ["<c-p>"] = { "select_prev", "fallback" },
        ["<c-n>"] = { "select_next", "fallback" },
        ["<cr>"] = { "accept", "fallback" },
        ["<c-y>"] = { "accept", "fallback" },

        -- ["<c-l>"] = { "show_signature", "hide_signature", "fallback" },
        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },


        ["<Up>"] = { "select_prev", "fallback" },
        ["<Down>"] = { "select_next", "fallback" },
        ["<c-k>"] = { "snippet_backward", "fallback" },
        ["<c-j>"] = { "snippet_forward", "fallback" },

        ["<C-space>"] = { "show", "hide" },
    },
    completion = {
        list = { selection = { preselect = false, auto_insert = false } },
        menu = {
            border = constants.wins.border,
            draw = {
                columns = { { "kind_icon", "label", "label_description", gap = 1 }, { "kind" } },
            },
        },
    },

    signature = { enabled = true, window = { border = constants.wins.border } },

    cmdline = {
        keymap = {
            ["<c-p>"] = { "select_prev", "show", "fallback" },
            ["<c-n>"] = { "select_next", "show", "fallback" },
            ["<tab>"] = { "select_next", "show", "fallback" },
            ["<s-tab>"] = { "select_prev", "show", "fallback" },

            ["<cr>"] = { "accept", "fallback" },
            ["<c-y>"] = { "accept", "fallback" },

            ["<Up>"] = { "select_prev", "fallback" },
            ["<Down>"] = { "select_next", "fallback" },
            ["<C-space>"] = { "show", "hide" },
        },
    },

    appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = "mono",
        kind_icons = constants.icons.kinds,
    },
    sources = {
        default = { "lazydev", "lsp", "path", "snippets", "buffer" },
        providers = {
            lazydev = {
                name = "LazyDev",
                module = "lazydev.integrations.blink",
                score_offset = 100,
            },
        },
    },
})
