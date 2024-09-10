if not nixCats("git") then
    return
end

require("gitsigns").setup({
    signs = {
        add = { text = "▐" },
        change = { text = "▐" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "▐" },
        untracked = { text = "▐" },
    },
    signs_staged = {
        add = { text = "▐" },
        change = { text = "▐" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "▐" },
        untracked = { text = "▐" },
    },
    signcolumn = true,
    numhl = false,
    linehl = false,
    word_diff = false,
    watch_gitdir = {
        interval = 1000,
        follow_files = true,
    },
    attach_to_untracked = true,
    current_line_blame = false,
    current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 1000,
        ignore_whitespace = false,
    },
    current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
    sign_priority = 6,
    update_debounce = 100,
    status_formatter = nil,
    max_file_length = 40000,
    preview_config = {
        border = "single",
        style = "minimal",
        relative = "cursor",
        row = 0,
        col = 1,
    },
})

local compose_hl = require("utils").compose_hl
vim.api.nvim_set_hl(0, "GitSignsUntracked", compose_hl({ link = "@method" }))
vim.api.nvim_set_hl(0, "GitSignsChange", compose_hl({ link = "@class" }))
vim.api.nvim_set_hl(0, "GitSignsChangedelete", compose_hl({ link = "@constant" }))
