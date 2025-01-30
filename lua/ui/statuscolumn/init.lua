if not nixCats("ui.statuscolumn") then
    return
end
local utf8sub = require("utils").utf8sub
local builder = require("ui.linebuilder")
local part = builder.part

local M = {}

local cache = {}
local function init_cache(win)
    cache = {}
    cache.lines = {}
    local first_line = vim.fn.line("w0", win)
    local last_line = vim.fn.line("w$", win)
    local buf = vim.api.nvim_win_get_buf(win)
    local ns_ids = vim.api.nvim_get_namespaces()
    for line = first_line, last_line do
        cache.lines[line] = {}
        for _, ns_id in pairs(ns_ids) do
            cache.lines[line][ns_id] = {}
        end
    end

    for _, ns_id in pairs(ns_ids) do
        for _, sign in ipairs(vim.api.nvim_buf_get_extmarks(
            buf, ns_id,
            { first_line - 1, 0 },
            { last_line - 1, -1 },
            { type = "sign", details = true }
        )) do
            table.insert(cache.lines[sign[2] + 1][ns_id], sign)
        end
    end

    local empty_ns_lines = {}
    for line = first_line, last_line do
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
        local visible_lines = last_line - first_line + 1
        local is_ns_emtpy = empty_ns_lines[ns_id] >= visible_lines
        cache.ns_empty[ns_id] = is_ns_emtpy
    end
    cache.ns_ids = ns_ids

    cache.folds = {}

    local cursor_line = vim.fn.line(".")
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
    cache.drawn_fold_starts = {}
    cache.drawn_fold_end_skips = {}
    for i = first_line, last_line do
        cache.drawn_fold_end_skips[i] = vim.fn.screenpos(win, line, vim.fn.col({ line, "$" })).row -
            vim.fn.screenpos(win, line, 0).row
    end
end


function _G.click_handlers.click_line(minwid, num_clicks, btn, mods)
    local mouse = vim.fn.getmousepos()
    vim.api.nvim_win_set_cursor(mouse.winid, { mouse.line, 0 })
end

---Implemetns the number colomn with _some_ support for vims options
---@param win integer The window id of the column drawn
---@param line integer What line we are at
---@return nixovim.ui.line.Part
local function number_column(win, line)
    local hl
    local is_focused = win == vim.api.nvim_get_current_win()
    if vim.v.relnum == 0 and vim.wo.relativenumber and is_focused then
        hl = "StcCurrentLineNumber"
    else
        hl = "StcLineNumber"
    end
    return part("%l", false, hl, "v:lua.click_handlers.click_line")
end

local function fold_column(win, line)
    if (not cache) or (not cache.folds)  then return end
    if cache.folds.hide then
        return part("", false)
    elseif cache.folds.fold_level == 0 or not cache.is_focused_window then
        return part(" ", false, "StcFold")
    elseif cache.folds.on_closed_fold and line == cache.folds.start_line then
        return part("🭽", false, "StcFolded")
    elseif cache.folds.on_closed_fold and line == cache.folds.end_line + 1 then
        return part("▔", false, "StcFolded")
    elseif line == cache.folds.start_line then
        local has_drawn_start = cache.drawn_fold_starts[line]
        cache.drawn_fold_starts[line] = true
        return part(has_drawn_start and "▏" or "🭽", false, "StcFold")
    elseif cache.folds.start_line < line and line < cache.folds.end_line then
        return part("▏", false, "StcFold")
    elseif line == cache.folds.end_line then
        local is_last = cache.drawn_fold_end_skips[line] <= 0
        cache.drawn_fold_end_skips[line] = cache.drawn_fold_end_skips[line] - 1
        return part(is_last and "🭼" or "▏", false, "StcFold")
    else
        return part(" ", false, "StcFold")
    end
end

---Shows sign with highest priority matching the filter
---@param win integer The window id of the column drawn
---@param line integer What line we are at
---@param filter? any
---@param opts? any
---@return nixovim.ui.line.Part
local function signs(win, line, filter, opts)
    local width = opts and opts.width or 2
    local hide_empty = opts and opts.hide_empty or false
    local ns_ids = vim.iter(cache.ns_ids or vim.api.nvim_get_namespaces())
        :map(function (name, id)
            if (filter == nil) or filter(name) then return id end
        end)
        :totable()
    if hide_empty and vim.iter(ns_ids):all(function (ns_id)
            return cache.ns_empty and cache.ns_empty[ns_id] and cache.ns_empty[ns_id]
        end) then
        width = 0
    end
    local extmarks = vim.iter(ns_ids)
        :map(function (ns_id)
            return cache.lines and cache.lines[line] and cache.lines[line][ns_id]
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
    local text = (" "):rep(width, "")
    if extmark and extmark[4] and extmark[4].sign_text then
        text = utf8sub(extmark[4].sign_text, 1, width)
    end
    return part(text, false, extmark[4].sign_hl_group)
end

---Defines my status column
---@return string
function StatusColumn()
    local win = vim.g.statusline_winid
    if not vim.wo[win].statuscolumn then
        return ""
    end
    local line = vim.v.lnum
    local first_line = vim.fn.line("w0", win)
    local last_line = vim.fn.line("w$", win)

    if line < first_line or last_line < line then
        return ""
    end

    if line == first_line then
        init_cache(win)
    end

    local stc = part({
        signs(win, line,
            function (name)
                return not (name:match("vim%.lsp%..+%..+%/diagnostic%/signs")
                    or name:match("gitsigns_signs.*"))
            end, { width = 2, hide_empty = true }),
        signs(win, line, function (name) return name:match("vim%.lsp%..+%..+%/diagnostic%/signs") end, { width = 2 }),
        fold_column(win, line),
        number_column(win, line),
        signs(win, line, function (name) return name:match("gitsigns_signs_.*") end, { width = 1 }),
    }, false, line == vim.fn.line(".") and "StcCurrentLineNumber" or "StcLineNumber")

    local res = builder.part_to_str(stc)

    return res
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
