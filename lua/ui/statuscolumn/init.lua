if not nixCats("ui.statuscolumn") then
    return
end
local utf8sub = require("utils").utf8sub
local builder = require("ui.linebuilder")
local part = builder.part

local M = {}

function _G.click_handlers.click_line(minwid, num_clicks, btn, mods)
    local mouse = vim.fn.getmousepos()
    vim.api.nvim_win_set_cursor(mouse.winid, { mouse.line, 0 })
end

---Implemetns the number colomn with _some_ support for vims options
---@param win integer The window id of the column drawn
---@param line integer What line we are at
---@return nixovim.ui.line.Part
local function number_column(win, line)
    if line < 1 or ((not vim.wo[win].relativenumber) and (not vim.wo[win].number)) then
        return part()
    end
    local width = math.max(vim.wo[win].numberwidth, #tostring(vim.fn.line("w$", win)) + 1)
    local is_focused = win == vim.api.nvim_get_current_win()
    local num_str
    local hl
    if vim.v.relnum == 0 and vim.wo.relativenumber and is_focused then
        num_str = string.format("%-" .. tostring(width) .. "d", line)
        hl = "StcCurrentLineNumber"
    else
        num_str = string.format("%" .. tostring(width) .. "d", is_focused and vim.v.relnum or line)
        hl = "StcLineNumber"
    end
    return part(num_str, false, hl, "v:lua.click_handlers.click_line")
end

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
        number_column(win, line),
        signs(win, line, function (name) return name:match("gitsigns_signs_.*") end, { width = 1 }),
    }, false, "StcLineNumber")

    local res = builder.part_to_str(stc)

    return res
end

local hl = require("utils").compose_hl

vim.api.nvim_set_hl(0, "StcSignColumn", hl({ link = "SignColumn" }))
vim.api.nvim_set_hl(0, "StcFoldColumn", hl({ link = "FoldColumn" }))
vim.api.nvim_set_hl(0, "StcLineNumber", hl({ link = "LineNr" }))
vim.api.nvim_set_hl(0, "StcCurrentLineNumber", hl({ link = "CursorLine", bold = true }))

vim.o.statuscolumn = "%!v:lua.StatusColumn()"
vim.o.numberwidth = 4

return M
