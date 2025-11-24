local utf8sub = require("utils").utf8sub
local foldexpr = require("utils").foldexpr

_G.stc_click_handlers = _G.stc_click_handlers or {}

local M = {}
local cache = {}

local function is_supported_window(win)
    if not win then
        return false
    end
    if not vim.api.nvim_win_is_valid(win) then
        return false
    end
    local config = vim.api.nvim_win_get_config(win)
    return config.relative == ""
end

local function normalize_win(win)
    if type(win) == "string" then
        return tonumber(win)
    end
    return win
end

function M.init_cache()
    cache = {}
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if is_supported_window(win) then
            M.init_window_cache(win)
        end
    end
end

---@param win number
---@param name string
---@param filter fun(ns: string): boolean
---@param width integer
function M.assign_sign_column(win, name, filter, width)
    local win_cache = cache[win]
    local column = {}
    local is_empty = true

    for lnum = win_cache.first_line, win_cache.last_line do
        local best
        for _, mark in ipairs(win_cache.lines[lnum] or {}) do
            local ns = win_cache.ns_reverse[mark.details.ns_id]
            if (not filter or filter(ns)) and mark.details.sign_text then
                if not best
                    or mark.details.priority > best.details.priority
                    or (mark.details.priority == best.details.priority and mark.details.ns_id < best.details.ns_id) then
                    best = mark
                end
            end
        end
        column[lnum] = best
        if best then is_empty = false end
    end

    win_cache.sign_columns = win_cache.sign_columns or {}
    win_cache.sign_columns[name] = {
        assigned = column,
        empty = is_empty,
        width = width,
    }
end

function M.init_window_cache(win)
    if not is_supported_window(win) then
        cache[win] = nil
        return nil
    end
    cache[win] = {}
    local win_cache = cache[win]
    win_cache.lines = {}
    win_cache.first_line = vim.fn.line("w0", win)
    win_cache.cursor_line = vim.fn.line(".", win)
    win_cache.last_line = vim.fn.line("w$", win)
    if vim.wo[win].relativenumber and not vim.wo[win].number then
        win_cache.numberwidth = math.max(3, vim.wo[win].numberwidth)
    elseif vim.wo[win].number then
        win_cache.numberwidth = math.max(vim.wo[win].numberwidth, string.len(tostring(win_cache.last_line)) + 1)
    else
        win_cache.numberwidth = 0
    end

    local buf = vim.api.nvim_win_get_buf(win)
    win_cache.win = win
    win_cache.buf = buf
    local ns_ids = vim.api.nvim_get_namespaces()
    win_cache.ns_reverse = {}
    for name, id in pairs(ns_ids) do
        win_cache.ns_reverse[id] = name
    end

    local extmarks = vim.api.nvim_buf_get_extmarks(
        buf, -1,
        { win_cache.first_line - 1, 0 },
        { win_cache.last_line - 1, -1 },
        { details = true, type = "sign" }
    )

    for _, extmark in ipairs(extmarks) do
        local lnum = extmark[2] + 1
        win_cache.lines[lnum] = win_cache.lines[lnum] or {}
        table.insert(win_cache.lines[lnum], {
            id = extmark[1],
            row = extmark[2],
            col = extmark[3],
            details = extmark[4],
        })
    end

    M.assign_sign_column(win, "sign_misc", function (name)
        return not (name:find("diagnostic%.signs") or name:match("gitsigns_signs.*"))
    end, 2)

    M.assign_sign_column(win, "sign_diag", function (name)
        return name:match("diagnostic%.signs")
    end, 2)

    M.assign_sign_column(win, "sign_git", function (name)
        return name:match("gitsigns_signs_.*")
    end, 1)

    local infos = {}
    for line = win_cache.first_line, win_cache.last_line do
        infos[line] = foldexpr(line, win)
    end
    local cursor_info = infos[win_cache.cursor_line]

    win_cache.folds = {
        infos = infos,
        current = {
            first = cursor_info and cursor_info.start or 0,
            last = win_cache.cursor_line,
            level = cursor_info and cursor_info.level or 0,
        },
    }

    if cursor_info and cursor_info.start then
        local fold_start = cursor_info.start
        local start_info = infos[fold_start]
        if not start_info then
            start_info = foldexpr(fold_start, win)
            infos[fold_start] = start_info
        end

        local fold_end
        if start_info then
            fold_end = start_info["end"]
            if (not fold_end or fold_end < fold_start) and start_info.lines and start_info.lines > 0 then
                fold_end = fold_start + start_info.lines - 1
            end
        end

        if fold_end and fold_end >= fold_start then
            win_cache.folds.current.last = math.min(fold_end, win_cache.last_line)
        else
            for line = win_cache.cursor_line + 1, win_cache.last_line do
                local f = infos[line]
                if not (f and f.start) or f.start < fold_start then break end
                win_cache.folds.current.last = line
            end
        end
    end

    win_cache.folds.hide = vim.api.nvim_get_option_value("foldcolumn", { win = win }) == "0"
    return win_cache
end

function M.get(win)
    win = normalize_win(win)
    if not is_supported_window(win) then
        cache[win] = nil
        return nil
    end
    if not cache[win] then
        return M.init_window_cache(win)
    end
    return cache[win]
end

function M.clear(win)
    win = normalize_win(win)
    if win then
        cache[win] = nil
    end
end

function M.refresh(win)
    win = normalize_win(win)
    if not win then
        return
    end
    if is_supported_window(win) then
        M.init_window_cache(win)
    else
        cache[win] = nil
    end
end

local function resolve_numberwidth(win, win_cache)
    if win_cache and win_cache.numberwidth then
        return win_cache.numberwidth
    end
    if not vim.api.nvim_win_is_valid(win) then
        return 0
    end
    local wo = vim.wo[win]
    if wo.relativenumber and not wo.number then
        return math.max(3, wo.numberwidth)
    elseif wo.number then
        local last_line = vim.fn.line("w$", win)
        return math.max(wo.numberwidth, string.len(tostring(last_line)) + 1)
    end
    return 0
end

function M.signs(name, opts)
    opts = opts or {}
    opts.auto_hide = opts.auto_hide ~= nil and opts.auto_hide or false
    return {
        name = name,
        text = function ()
            local win_cache = M.get(vim.g.statusline_winid)
            local col = win_cache and win_cache.sign_columns[name]
            if not col then
                return ""
            end
            local mark = col.assigned[vim.v.lnum]
            if not mark then
                return opts.auto_hide and "" or string.rep(" ", col.width)
            end
            return utf8sub(mark.details.sign_text, 1, col.width)
        end,
        hl = function ()
            local win_cache = M.get(vim.g.statusline_winid)
            local mark = win_cache and win_cache.sign_columns[name].assigned[vim.v.lnum]
            return mark and mark.details.sign_hl_group or ""
        end,
    }
end

M.fold_column = {
    name = "fold",
    on_click = [[v:lua.stc_click_handlers.fold]],
    text = function ()
        local win_cache = M.get(vim.g.statusline_winid)
        local fillchars = vim.opt.fillchars:get()
        local char_closed = fillchars.foldclose or "+"
        local char_open = fillchars.foldopen or "-"
        local char_sep = fillchars.foldsep or " "
        local info = win_cache and win_cache.folds and win_cache.folds.infos and win_cache.folds.infos[vim.v.lnum]

        local text = " "

        if info and info.level >= 1 then
            local is_start = info.start == vim.v.lnum
            local is_closed = info.lines > 0
            if is_start then
                text = is_closed and char_closed or char_open
            else
                text = char_sep
            end
        end
        return text
    end,
    hl = function ()
        local win_cache = M.get(vim.g.statusline_winid)
        local lnum = vim.v.lnum
        local info = win_cache and win_cache.folds and win_cache.folds.infos and win_cache.folds.infos[lnum]
        local current = win_cache and win_cache.folds and win_cache.folds.current
        local hl = "StcFold"
        if info and info.level >= 1 then
            if current and current.level >= 1 and lnum >= current.first and lnum <= current.last then
                hl = "StcFoldCurrent"
            end
        end
        return hl
    end,
}

M.number_column = {
    name = "number",
    on_click = [[v:lua.stc_click_handlers.number]],
    text = function ()
        local win = vim.g.statusline_winid
        if not vim.api.nvim_win_is_valid(win) then
            return ""
        end
        local win_cache = M.get(win)
        local width = resolve_numberwidth(win, win_cache)
        if vim.v.virtnum ~= 0 or width == 0 then
            return string.rep(" ", width)
        end
        local wo = vim.wo[win]
        local number
        if wo.number and wo.relativenumber then
            number = (vim.v.relnum == 0) and vim.v.lnum or vim.v.relnum
        elseif wo.number then
            number = vim.v.lnum
        elseif wo.relativenumber then
            number = vim.v.relnum
        end
        if number then
            return string.format("%" .. ((vim.v.relnum == 0) and "-" or "") .. width .. "d", number)
        end
        return string.rep(" ", width)
    end,
    hl = function ()
        local win = vim.g.statusline_winid
        if vim.api.nvim_win_is_valid(win)
            and vim.v.relnum == 0
            and vim.wo[win].relativenumber then
            return "StcCurrentLineNumber"
        else
            return "StcLineNumber"
        end
    end,
}

M.whole = {
    children = {
        M.signs("sign_misc", { auto_hide = true }),
        M.signs("sign_diag"),
        M.fold_column,
        M.number_column,
        M.signs("sign_git"),
    },
}

M.click_handlers = _G.stc_click_handlers

---@diagnostic disable-next-line: unused-local
function M.click_handlers.number(minwid, num_clicks, btn, mods)
    local mouse = vim.fn.getmousepos()
    vim.api.nvim_win_set_cursor(mouse.winid, { mouse.line, 0 })
end

---@diagnostic disable-next-line: unused-local
function M.click_handlers.fold(minwid, num_clicks, btn, mods)
    local mouse = vim.fn.getmousepos()
    local win = mouse.winid
    local lnum = mouse.line

    if not vim.api.nvim_win_is_valid(win) then return end
    if lnum < 1 or lnum > vim.api.nvim_buf_line_count(0) then return end

    local fold_info = foldexpr(lnum, win)
    if fold_info and fold_info.start == lnum then
        if vim.fn.foldclosed(lnum) == -1 then
            vim.cmd(lnum .. "foldclose")
        else
            vim.cmd(lnum .. "foldopen")
        end
    end
end

return M
