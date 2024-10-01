local care = require("care")

local labels = { "1", "2", "3", "4", "5", "6", "7", "8", "9" }
care.setup({
    ui = {
        menu = {
            max_height = 10,
            border = "rounded",
            position = "auto",
            format_entry = function (entry, data)
                local preset_cmps=require("care.presets.components")
                return {
                    preset_cmps.KindIcon(entry, "fg"),
                    preset_cmps.Label(entry, data, false),
                    preset_cmps.KindName(entry, true)
                }
            end,
            scrollbar = "█",
            alignments = {},
        },
        docs_view = {
            max_height = 8,
            max_width = 80,
            border = "rounded",
            scrollbar = "█",
            position = "auto",
        },
        type_icons = {
            Class = "",
            Color = "",
            Constant = "",
            Constructor = "",
            Enum = "",
            EnumMember = "",
            Event = "",
            Field = "󰜢",
            File = "",
            Folder = "",
            Function = "",
            Interface = "",
            Keyword = "",
            Method = "ƒ",
            Module = "",
            Operator = "󰆕",
            Property = "",
            Reference = "",
            Snippet = "",
            Struct = "",
            Text = "",
            TypeParameter = "",
            Unit = "󰑭",
            Value = "󰎠",
            Variable = "󰫧",
        },
        ghost_text = {
            enabled = true,
            position = "overlay",
        },
    },
    snippet_expansion = function (snippet_body)
        vim.snippet.expand(snippet_body)
    end,
    selection_behavior = "select",
    confirm_behavior = "insert",
    keyword_pattern = [[\%(-\?\d\+\%(\.\d\+\)\?\|\h\w*\%(-\w*\)*\)]],
    sources = {},
    preselect = false,
    sorting_direction = "top-down",
    completion_events = { "TextChangedI" },
    enabled = function ()
        local enabled = true
        if vim.api.nvim_get_option_value("buftype", { buf = 0 }) == "prompt" then
            enabled = false
        end
        return enabled
    end,
    max_view_entries = 200,
    debug = false,
})

vim.keymap.set("i", "<c-space>", function ()
    care.api.complete()
end)

vim.keymap.set("i", "<c-p>", "<Plug>(CareSelectPrev)")
vim.keymap.set("i", "<c-n>", "<Plug>(CareSelectNext)")
vim.keymap.set("i", "<c-k>", "<Plug>(CareConfirm)")
vim.keymap.set("i", "<c-e>", "<Plug>(CareClose)")

vim.keymap.set("i", "<cr>", function ()
    if care.api.is_open() and care.api.get_index() ~= 0 then
        care.api.confirm()
    else
        vim.api.nvim_feedkeys(vim.keycode("<cr>"), "n", false)
    end
end)

vim.keymap.set("i", "<c-f>", function ()
    if care.api.doc_is_open() then
        care.api.scroll_docs(4)
    else
        vim.api.nvim_feedkeys(vim.keycode("<c-f>"), "i", false)
    end
end)

vim.keymap.set("i", "<c-d>", function ()
    if care.api.doc_is_open() then
        care.api.scroll_docs(-4)
    else
        vim.api.nvim_feedkeys(vim.keycode("<c-f>"), "n", false)
    end
end)

vim.keymap.set("i", "<c-f>", function ()
    if care.api.doc_is_open() then
        care.api.scroll_docs(4)
    else
        vim.api.nvim_feedkeys(vim.keycode("<c-f>"), "n", false)
    end
end)

for i, label in ipairs(labels) do
    vim.keymap.set("i", "<c-" .. label .. ">", function ()
        care.api.select_visible(i)
        care.api.confirm()
    end)
end

vim.keymap.set("i", "<c-x><c-o>", function ()
    care.api.complete(function (name)
        return name == "lsp"
    end)
end)

vim.keymap.set("i", "<c-x><c-l>", function ()
    care.api.complete(function (name)
        return name == "cmp_buffer-lines"
    end)
end)

vim.keymap.set("i", "<c-x><c-f>", function ()
    care.api.complete(function (name)
        return name == "cmp_path"
    end)
end)

vim.keymap.set("i", "<c-x><c-s>", function ()
    care.api.complete(function (name)
        return name == "cmp_spell"
    end)
end)

vim.api.nvim_create_augroup("AutoComplete", { clear = true })
vim.api.nvim_create_autocmd("InsertEnter", {
    group = "AutoComplete",
    callback = function ()
        local function is_right_to_dot()
            local col = vim.fn.col(".") - 1
            if col == 0 then
                return false
            end
            local char_left = vim.fn.getline("."):sub(col, col)
            return char_left == "."
        end
        if is_right_to_dot() then
            care.api.complete()
        end
    end,
})
