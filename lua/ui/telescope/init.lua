if not nixCats("ui.telescope.enabled") then
    return
end
local keys = {}
if nixCats("ui.telescope.fileFinder") then
    table.insert(keys, { "<space><space>", "<cmd>Telescope find_files<cr>", desc = "Files" })
end
if nixCats("ui.telescope.liveSearch") then
    table.insert(keys, { "<space>/", "<cmd>Telescope live_grep<cr>", desc = "Search" })
end
if nixCats("ui.telescope.buffers") then
    table.insert(keys, { "<c-w>b", "<cmd>Telescope buffers<cr>", desc = "Buffers" })
end
if nixCats("ui.telescope.resession") then
    table.insert(keys, { "<leader>r", "<cmd>Telescope resession<cr>", desc = "Sessions" })
end

require("lz.n").load({
    "telescope.nvim",
    keys = keys,
    cmd = { "Telescope" },
    after = function ()
        local telescope = require("telescope")
        local border = require("constants").wins.border
        border = vim.iter({ 2, 4, 6, 8, 1, 3, 5, 7 }):map(function (idx) return border[idx] end):totable()

        local extensions = {}

        if nixCats("ui.telescope.resession") then
            extensions.resession = {
                prompt_title = "Find session",
                path_substitutions = {},
            }
        end

        telescope.setup({
            defaults = {
                border = true,
                theme = "center",
                layout_config = { horizontal = { prompt_position = "top", preview_width = 0.5 } },
                layout_strategy = "horizontal",
                prompt_prefix = " ",
                selection_caret = " ",
                sorting_strategy = "ascending",
                winblend = 0,
                borderchars = border,
            },
            pickers = {},
            extensions = extensions,
        })

        local themes = require("telescope.themes")
        for key, value in pairs(themes) do
            local original_theme = themes[key]
            themes[key] = function (opts)
                return original_theme(vim.tbl_deep_extend("keep", opts, { borderchars = border }))
            end
        end


        for ext_name, _ in pairs(extensions) do
            telescope.load_extension(ext_name)
        end
    end,
})
