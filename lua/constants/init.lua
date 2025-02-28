return {
    signs = {
        diagnostics = {
            [vim.diagnostic.severity.ERROR] = { name = "DiagnosticSignError", text = "", texthl = "DiagnosticError" },
            [vim.diagnostic.severity.WARN] = { name = "DiagnosticSignWarn", text = "", texthl = "DiagnosticWarn" },
            [vim.diagnostic.severity.HINT] = { name = "DiagnosticSignHint", text = "", texthl = "DiagnosticHint" },
            [vim.diagnostic.severity.INFO] = { name = "DiagnosticSignInfo", text = "", texthl = "DiagnosticInfo" },
        },
    },
    icons = {
        kinds = {
            Text = "󰉿",
            Method = "󰊕",
            Function = "󰊕",
            Constructor = "󰒓",

            Field = "󰜢",
            Variable = "󰆦",
            Property = "󰖷",

            Class = "󱡠",
            Interface = "󱡠",
            Struct = "󱡠",
            Module = "󰅩",

            Unit = "󰪚",
            Value = "󰦨",
            Enum = "󰦨",
            EnumMember = "󰦨",

            Keyword = "󰻾",
            Constant = "󰏿",

            Snippet = "󱄽",
            Color = "󰏘",
            File = "󰈔",
            Reference = "󰬲",
            Folder = "󰉋",
            Event = "󱐋",
            Operator = "󰪚",
            TypeParameter = "󰬛",
        },
    },
    wins = {
        border = { "🭽", "▔", "🭾", "▕", "🭿", "▁", "🭼", "▏" },
        scroller = "▐",
    },
}
