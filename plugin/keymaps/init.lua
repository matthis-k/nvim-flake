local Snacks = require("snacks")
local keymaps = require("keymaps")
vim.g.mapleader = keymaps.leader
vim.g.maplocalleader = keymaps.leader

require("which-key").setup({
    delay = 0,
    filter = nil,
    spec = nil,
    notify = true,
    defer = nil,
    plugins = nil,
    keys = nil,
    sort = nil,
    expand = 1,
    replace = nil,
    debug = false,
    preset = "classic",
    icons = {
        breadcrumb = "»",
        separator = "➜",
        group = "+",
    },
    win = {
        border = require("constants").wins.border,
        wo = { winblend = 0 },
    },
    layout = {
        height = { min = 4, max = 25 },
        width = { min = 20, max = 50 },
        spacing = 3,
        align = "center",
    },
    show_help = false,
    show_keys = true,
    triggers = {
        { "<auto>", mode = "nixsoc" },
    },
    disable = {
        buftypes = {},
        filetypes = {},
    },
})


for _, km in ipairs(keymaps.maps or {}) do
    Snacks.keymap.set(km.mode, km.lhs, km.rhs, km.opts)
end
