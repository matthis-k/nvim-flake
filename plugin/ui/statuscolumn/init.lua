if not nixCats("ui.statuscolumn") then
    return
end

local stc = require("ui.statuscolumn")

---Defines my status column
---@return string
function StatusColumn()
    local win = vim.g.statusline_winid
    if not vim.wo[win].statuscolumn then
        return ""
    end

    local ok, first_line = pcall(vim.fn.line, "w0", win)
    if not ok then return "" end
    local last_line = vim.fn.line("w$", win)

    if vim.v.lnum < first_line or last_line < vim.v.lnum then
        return ""
    end

    if vim.v.lnum == first_line then
        stc.init_cache(win)
    end

    return stc.whole:eval()
end

vim.o.statuscolumn = "%!v:lua.StatusColumn()"
vim.o.numberwidth = 4
