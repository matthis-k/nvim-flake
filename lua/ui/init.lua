if not nixCats("ui.enabled") then
    return
end

for _, file in ipairs(require("utils").dirs(nixCats.configDir .. "/lua/ui")) do
    local status, err = pcall(require, "ui." .. file.basename)
end

require("which-key").setup({
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
