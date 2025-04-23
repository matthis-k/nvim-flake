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


for _, km in ipairs(keymaps.permanent) do
    local mode, lhs, rhs, opts = unpack(km)
    vim.keymap.set(mode, lhs, rhs, opts)
end

if nixCats("lsp.enabled") then
    vim.api.nvim_create_augroup("LspKeymaps", { clear = true })
    vim.api.nvim_create_autocmd("LspAttach", {
        group = "LspKeymaps",
        callback = function (ev)
            local client = vim.lsp.get_client_by_id(ev.data.client_id)
            if not client then
                return
            end
            for method, capability_maps in pairs(keymaps.lsp_maps_by_capability) do
                if method == "no_requirements" or client:supports_method(method) then
                    for _, keymap in ipairs(capability_maps) do
                        local modes, lhs, rhs, opts = unpack(keymap)
                        opts = opts or {}
                        opts.buffer = true
                        vim.keymap.set(modes, lhs, rhs, opts)
                    end
                end
            end
        end,
    })
end
