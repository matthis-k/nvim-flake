local utf8sub = require("utils").utf8sub
local foldexpr = require("utils").foldexpr
local Part = require("ui.lib.linepart")

local M = {}

local cache = {}
function M.init_cache(win)
    cache = {}
    cache.lines = {}
    cache.first_line = vim.fn.line("w0", win)
    cache.cursor_line = vim.fn.line(".", win)
    cache.last_line = vim.fn.line("w$", win)
    if vim.wo[win].relativenumber and not vim.wo[win].number then
        cache.numberwidth = math.max(3, vim.wo[win].numberwidth)
    elseif vim.wo[win].number then
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

    cache.folds = {
        current = {
            first = cache.first_line,
            last = cache.last_line,
            level = vim.fn.foldlevel("."),
        },
    }
    for line = cache.cursor_line, cache.first_line, -1 do
        ---@type string
        local fold_str = foldexpr(line, win)
        if fold_str:match("^[a>]" .. cache.folds.current.level) then
            cache.folds.current.first = line
            break
        end
    end
    for line = cache.cursor_line, cache.last_line do
        ---@type string
        local fold_str = foldexpr(line, win)
        if fold_str:match("^[<s]" .. cache.folds.current.level) then
            cache.folds.current.last = line
            break
        end
    end
    cache.folds.hide = vim.api.nvim_get_option_value("foldcolumn", { win = win }) == "0"
end

---@diagnostic disable-next-line: unused-local, duplicate-set-field
function _G.click_handlers.click_line(minwid, num_clicks, btn, mods)
    local mouse = vim.fn.getmousepos()
    vim.api.nvim_win_set_cursor(mouse.winid, { mouse.line, 0 })
end

---@diagnostic disable-next-line: unused-local, duplicate-set-field
function _G.click_handlers.click_fold(minwid, clicks, button, mods)
    local mouse = vim.fn.getmousepos()
    local win = mouse.winid
    local lnum = mouse.line
    local fold_str = foldexpr(lnum, win)

    if fold_str:match("^>%d+") then
        if vim.fn.foldclosed(lnum) == -1 then
            vim.cmd(lnum .. "foldclose")
        else
            vim.cmd(lnum .. "foldopen")
        end
    else
        vim.api.nvim_win_set_cursor(win, { lnum, 0 })
    end
end

local number_column = Part()
    :cache(function (lcache, shared)
        lcache.is_focused = shared.win == vim.api.nvim_get_current_win()
        lcache.show_relative = lcache.is_focused and vim.wo[shared.win].relativenumber
    end)
    ---@diagnostic disable-next-line: unused-local
    :text(function (lcache, shared)
        local text = string.rep(" ", cache.numberwidth or 0)
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
    ---@diagnostic disable-next-line: unused-local
    :hl(function (lcache, shared)
        if vim.v.relnum == 0 and vim.wo[shared.win].relativenumber then
            return "StcCurrentLineNumber"
        else
            return "StcLineNumber"
        end
    end)
    :on_click("v:lua.click_handlers.click_line")

local fold_column = Part()
    ---@diagnostic disable-next-line: unused-local
    :cache(function (lcache, shared)
        local inside_current_fold = cache and cache.folds and
            cache.folds.current.first <= vim.v.lnum and
            cache.folds.current.last >= vim.v.lnum

        local hl = (inside_current_fold and cache.folds.current.level >= 1) and "StcFoldCurrent" or "StcFold"
        local text = " "

        ---@type string
        local fold_str = foldexpr()
        if fold_str:match("^[a>]%d+") then
            local is_closed = vim.fn.foldclosed(vim.v.lnum) > 0
            text = is_closed and "+" or "-"
        end

        lcache.text = text
        lcache.hl = hl
    end)
    :text(function (lcache) return lcache.text end)
    :hl(function (lcache) return lcache.hl end)
    :on_click("v:lua.click_handlers.click_fold")

local function signs(opts)
    return Part()
        ---@diagnostic disable-next-line: unused-local
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
        ---@diagnostic disable-next-line: unused-local
        :text(function (lcache, shared)
            return lcache.text
        end)
        ---@diagnostic disable-next-line: unused-local
        :hl(function (lcache, shared)
            return lcache.hl
        end)
end


M.whole = Part():cache(function (_, shared) shared.win = vim.g.statusline_winid end):children({
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

return M
