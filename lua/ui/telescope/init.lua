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
    "telescope-nvim",
    keys = keys,
    cmd = { "Telescope" },
    after = function ()
        local telescope = require("telescope")

        local extensions = {}

        if nixCats("ui.telescope.resession") then
            extensions.resession = {
                prompt_title = "Find session",
                path_substitutions = {},
            }
        end

        telescope.setup({
            defaults = {
                mappings = {
                    i = {
                        ["<C-h>"] = "which_key",
                    },
                },
            },
            pickers = {},
            extensions = extensions,
        })
        for ext_name, _ in pairs(extensions) do
            telescope.load_extension(ext_name)
        end
    end,
})
