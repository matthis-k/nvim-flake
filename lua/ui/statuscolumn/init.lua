if not nixCats("ui.statuscolumn") then
    return
end
local utf8sub = require("utils").utf8sub
local Part = require("ui.lib.linepart")

local M = {}

local cache = {}
local function init_cache(win)
    cache = {}
    cache.lines = {}
    cache.first_line = vim.fn.line("w0", win)
    cache.cursor_line = vim.fn.line(".", win)
    cache.last_line = vim.fn.line("w$", win)
    if vim.wo[win].relativenumber and not vim.wo[win].number then
        cache.numberwidth = math.max(3, vim.wo[win].numberwidth)
    elseif vim.wo.number then
        cache.numberwidth = math.max(vim.wo[win].numberwidth, string.len(tostring(cache.last_line)) + 1)
    else
        cache.numberwidth = 0
    end
    local buf = vim.api.nvim_win_get_buf(win)
    local ns_ids = vim.api.nvim_get_namespaces()
    for line = cache.first_line, cache.last_line do
        cache.lines[line] = {}
        for _, ns_id in pairs(ns_ids) do
            cache.lines[line][ns_id] = {}
        end
    end

    for _, ns_id in pairs(ns_ids) do
        for _, sign in ipairs(vim.api.nvim_buf_get_extmarks(
            buf, ns_id,
            { cache.first_line - 1, 0 },
            { cache.last_line - 1, -1 },
            { type = "sign", details = true }
        )) do
            table.insert(cache.lines[sign[2] + 1][ns_id], sign)
        end
    end

    local empty_ns_lines = {}
    for line = cache.first_line, cache.last_line do
        for _, ns_id in pairs(ns_ids) do
            local ns_cache = cache.lines[line][ns_id]
            empty_ns_lines[ns_id] = empty_ns_lines[ns_id] or 0
            if #ns_cache == 0 then
                empty_ns_lines[ns_id] = empty_ns_lines[ns_id] + 1
            end
        end
    end
    cache.ns_empty = {}
    for _, ns_id in pairs(ns_ids) do
        local visible_lines = cache.last_line - cache.first_line + 1
        local is_ns_emtpy = empty_ns_lines[ns_id] >= visible_lines
        cache.ns_empty[ns_id] = is_ns_emtpy
    end
    cache.ns_ids = ns_ids

    cache.folds = {}

    local cursor_line = cache.cursor_line
    local fold_level = vim.fn.foldlevel(cursor_line)

    local start_line = cursor_line
    while start_line >= vim.fn.line("w0", win) and vim.fn.foldlevel(start_line - 1) >= fold_level do
        start_line = start_line - 1
    end
    local end_line = cursor_line
    while end_line < vim.fn.line("w$", win) and vim.fn.foldlevel(end_line + 1) >= fold_level do
        end_line = end_line + 1
    end
    cache.folds.start_line = start_line
    cache.folds.end_line = end_line
    cache.folds.hide = vim.api.nvim_get_option_value("foldcolumn", { win = win }) == "0"
    cache.folds.fold_level = vim.fn.foldlevel(".")
    cache.folds.on_closed_fold = vim.fn.foldclosed(cursor_line) ~= -1
    cache.is_focused_window = vim.api.nvim_get_current_win() == win
end


function _G.click_handlers.click_line(minwid, num_clicks, btn, mods)
    local mouse = vim.fn.getmousepos()
    vim.api.nvim_win_set_cursor(mouse.winid, { mouse.line, 0 })
end

local number_column = Part()
    :cache(function (lcache, shared)
        lcache.is_focused = shared.win == vim.api.nvim_get_current_win()
        lcache.show_relative = is_focused and vim.wo[shared.win].relativenumber
    end)
    :text(function (lcache, shared)
        text = string.rep(" ", cache.numberwidth or 0)
        if vim.v.virtnum == 0 and cache.numberwidth and cache.numberwidth > 0 then
            local number
            if vim.wo[shared.win].number and vim.wo[shared.win].relativenumber then
                number = (vim.v.relnum == 0) and vim.v.lnum or vim.v.relnum
            elseif vim.wo[shared.win].number then
                number = vim.v.lnum
            elseif vim.wo[shared.win].relativenumber then
                number = vim.v.relnum
            end
            if number then
                text = string.format("%" .. ((vim.v.relnum == 0) and "-" or "") .. cache.numberwidth .. "d", number)
            end
        end
        return text
    end)
    :hl(function (lcache, shared)
        if vim.v.relnum == 0 and vim.wo[shared.win].relativenumber then
            return "StcCurrentLineNumber"
        else
            return "StcLineNumber"
        end
    end)
    :on_click("v:lua.click_handlers.click_line")

local fold_column = Part()
    :cache(function (lcache, shared)
        if (not cache) or (not cache.folds) then return end
        local symbol = ""
        local hl = "StcFold"
        if cache.folds.hide then
        elseif cache.folds.fold_level == 0 or not cache.is_focused_window then
            symbol = " "
        elseif cache.folds.on_closed_fold and vim.v.lnum == cache.folds.start_line and vim.v.virtnum == 0 then
            symbol, hl = "🭽", "StcFolded"
        elseif cache.folds.on_closed_fold and vim.v.lnum == cache.folds.start_line and vim.v.virtnum > 0 then
            symbol, hl = "▏", "StcFolded"
        elseif cache.folds.on_closed_fold and vim.v.lnum == cache.folds.end_line + 1 then
            symbol, hl = "▔", "StcFolded"
        elseif vim.v.lnum == cache.folds.start_line and vim.v.virtnum == 0 then
            symbol = "🭽"
        elseif vim.v.lnum == cache.folds.start_line then
            symbol = "▏"
        elseif cache.folds.start_line < vim.v.lnum and vim.v.lnum < cache.folds.end_line then
            symbol = "▏"
        elseif vim.v.lnum == cache.folds.end_line then
            local total_wraps = 0
            local win_width = vim.api.nvim_win_get_width(shared.win)
            local buf = vim.api.nvim_win_get_buf(shared.win)
            local text = vim.api.nvim_buf_get_lines(buf, vim.v.lnum - 1, vim.v.lnum, false)[1] or ""
            local text_width = vim.fn.strwidth(text)
            local wrap_enabled = vim.wo.wrap
            if wrap_enabled then
                total_wraps = math.floor(text_width / win_width)
            end
            symbol = vim.v.virtnum == total_wraps and "🭼" or "▏"
        else
            symbol = " "
        end
        lcache.text = symbol
        lcache.hl = hl
    end)
    :text(function (lcache, shared)
        return lcache.text
    end)
    :hl(function (lcache, shared)
        return lcache.hl
    end)

local function signs(opts)
    return Part()
        :cache(function (lcache, shared)
            for k, v in pairs(opts) do
                lcache[k] = v
            end
            local width = lcache.width or 2
            local hide_empty = lcache.hide_empty or false
            local fill_char = lcache.fill_char or " "
            local ns_ids = vim.iter(cache.ns_ids or vim.api.nvim_get_namespaces())
                :map(function (name, id)
                    if (lcache.filter == nil) or lcache.filter(name) then return id end
                end)
                :totable()
            if hide_empty and vim.iter(ns_ids):all(function (ns_id)
                    return cache.ns_empty and cache.ns_empty[ns_id] and cache.ns_empty[ns_id]
                end) then
                width = 0
            end
            local extmarks = vim.iter(ns_ids)
                :map(function (ns_id)
                    return cache.lines and cache.lines[vim.v.lnum] and cache.lines[vim.v.lnum][ns_id]
                end)
                :flatten()
                :totable()
            local extmark = vim.iter(extmarks)
                :fold({ [4] = { priority = 0 } }, function (acc, cur)
                    if acc[4].priority < cur[4].priority
                        or (acc[4].priority == cur[4].priority and acc[4].ns_id < cur[4].ns_id) then
                        acc = cur
                    end
                    return acc
                end)
            local text = (fill_char):rep(width)
            if extmark and extmark[4] and extmark[4].sign_text then
                text = utf8sub(extmark[4].sign_text, 1, width)
            end
            lcache.text = text
            lcache.hl = extmark[4].sign_hl_group
        end)
        :text(function (lcache, shared)
            return lcache.text
        end)
        :hl(function (lcache, shared)
            return lcache.hl
        end)
end

local stc = Part():cache(function (_, shared) shared.win = vim.g.statusline_winid end):children({
    signs({
        filter = function (name)
            return not (name:match("vim%.lsp%..+%..+[%.%/]diagnostic[%.%/]signs")
                or name:match("gitsigns_signs.*"))
        end,
        hide_empty = true,
    }),
    signs({ filter = function (name) return name:match("vim%.lsp%..+%..+[%.%/]diagnostic[%.%/]signs") end }),
    fold_column,
    number_column,
    signs({
        filter = function (name) return name:match("gitsigns_signs_.*") end,
        width = 1,
    }),
})

---Defines my status column
---@return string
function StatusColumn()
    local win = vim.g.statusline_winid
    if not vim.wo[win].statuscolumn then
        return ""
    end

    local first_line = vim.fn.line("w0", win)
    local last_line = vim.fn.line("w$", win)

    if vim.v.lnum < first_line or last_line < vim.v.lnum then
        return ""
    end

    if vim.v.lnum == first_line then
        init_cache(win)
    end

    return stc:eval()
end

local hl = require("utils").compose_hl

vim.api.nvim_set_hl(0, "StcSignColumn", hl({ link = "SignColumn" }))
vim.api.nvim_set_hl(0, "StcFoldColumn", hl({ link = "FoldColumn" }))
vim.api.nvim_set_hl(0, "StcLineNumber", hl({ link = "LineNr" }))
vim.api.nvim_set_hl(0, "StcCurrentLineNumber", hl({ link = "CursorLine", bold = true }))
vim.api.nvim_set_hl(0, "StcFold", hl({ fg = "FoldColumn" }))
vim.api.nvim_set_hl(0, "StcFolded", hl({ fg = "Folded" }))

vim.o.statuscolumn = "%!v:lua.StatusColumn()"
vim.o.numberwidth = 4

return M
