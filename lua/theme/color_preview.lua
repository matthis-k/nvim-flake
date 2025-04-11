local M = {}
local win_id = nil
local buf_id = nil

function M.toggle()
    if win_id and vim.api.nvim_win_is_valid(win_id) then
        vim.api.nvim_win_close(win_id, true)
        win_id = nil
        buf_id = nil
        return
    end

    local colors = require("base16-colorscheme").colors
    buf_id = vim.api.nvim_create_buf(false, true)

    local lines = {}
    for i = 0, 15 do
        local key = string.format("base0%X", i)
        local line_text = string.format("%s: ███", key)
        table.insert(lines, line_text)
    end
    vim.api.nvim_buf_set_lines(buf_id, 0, -1, false, lines)

    local max_width = 0
    for _, line in ipairs(lines) do
        local w = vim.fn.strdisplaywidth(line)
        if w > max_width then
            max_width = w
        end
    end
    local height = #lines

    local col = vim.o.columns - max_width - 2
    local row = 1

    win_id = vim.api.nvim_open_win(buf_id, false, {
        relative = "editor",
        width = max_width,
        height = height,
        row = row,
        col = col,
        style = "minimal",
        border = require("constants").wins.border,
    })

    local ns = vim.api.nvim_create_namespace("color_blocks")
    for i = 0, 15 do
        local key = string.format("base0%X", i)
        local hl_group = "ColorBlock_" .. key
        vim.api.nvim_set_hl(0, hl_group, { fg = colors[key] })
        local col_start = #key + 2
        vim.api.nvim_buf_add_highlight(buf_id, ns, hl_group, i, col_start, -1)
    end
end

return M
