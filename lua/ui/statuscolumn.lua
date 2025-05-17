local utf8sub = require("utils").utf8sub
local foldexpr = require("utils").foldexpr

local PROF_NAME = "statuscolumn"
local prof = require("profiler")(PROF_NAME)

local M = {}
local cache = {}

function M.init_cache()
    cache = {}
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_config(win).relative == "" then
            cache[win] = M.init_window_cache(win)
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
    prof:start("options")
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
    prof:stop("options")

    prof:start("extmarks")
    local buf = vim.api.nvim_win_get_buf(win)
    local ns_ids = vim.api.nvim_get_namespaces()
    win_cache.ns_reverse = {}
    for name, id in pairs(ns_ids) do
        win_cache.ns_reverse[id] = name
    end

    prof:start("get_extmarks")
    local extmarks = vim.api.nvim_buf_get_extmarks(
        buf, -1,
        { win_cache.first_line - 1, 0 },
        { win_cache.last_line - 1, -1 },
        { details = true, type = "sign" }
    )
    prof:stop("get_extmarks")

    prof:start("line_extmarks_map")
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
    prof:stop("line_extmarks_map")
    prof:stop("extmarks")

    M.assign_sign_column(win, "sign_misc", function (name)
        return not (name:find("diagnostic%.signs") or name:match("gitsigns_signs.*"))
    end, 2)

    M.assign_sign_column(win, "sign_diag", function (name)
        return name:match("diagnostic%.signs")
    end, 2)

    M.assign_sign_column(win, "sign_git", function (name)
        return name:match("gitsigns_signs_.*")
    end, 1)

    prof:start("folds")
    local infos = {}
    for line = win_cache.first_line, win_cache.last_line do
        infos[line] = foldexpr(line, win)
    end
    local cursor_info = infos[win_cache.cursor_line]

    win_cache.folds = {
        infos = infos,
        current = {
            first = cursor_info.start,
            last = win_cache.cursor_line,
            level = cursor_info.level or 0,
        },
    }

    for line = win_cache.cursor_line + 1, win_cache.last_line do
        local f = infos[line]
        if f.start < cursor_info.start then break end
        win_cache.folds.current.last = line
    end

    win_cache.folds.hide = vim.api.nvim_get_option_value("foldcolumn", { win = win }) == "0"
    return win_cache
end

function M.get(win)
    return cache[win]
end

function M.signs(name, opts)
    opts = opts or {}
    opts.auto_hide = opts.auto_hide ~= nil and opts.auto_hide or false
    return {
        name = name,
        text = function ()
            local win_cache = M.get(vim.g.statusline_winid)
            local col = win_cache.sign_columns[name]
            local mark = col.assigned[vim.v.lnum]
            if not mark then
                return opts.auto_hide and "" or string.rep(" ", col.width)
            end
            return utf8sub(mark.details.sign_text, 1, col.width)
        end,
        hl = function ()
            local win_cache = M.get(vim.g.statusline_winid)
            local mark = win_cache.sign_columns[name].assigned[vim.v.lnum]
            return mark and mark.details.sign_hl_group or ""
        end,
    }
end

M.fold_column = {
    name = "fold",
    on_click = "v:lua.click_handlers.click_fold",
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
    on_click = "v:lua.click_handlers.click_line",
    text = function ()
        local win_cache = M.get(vim.g.statusline_winid)
        local width = win_cache.numberwidth
        if vim.v.virtnum ~= 0 or width == 0 then
            return string.rep(" ", width)
        end
        local number
        if vim.wo[vim.g.statusline_winid].number and vim.wo[vim.g.statusline_winid].relativenumber then
            number = (vim.v.relnum == 0) and vim.v.lnum or vim.v.relnum
        elseif vim.wo[vim.g.statusline_winid].number then
            number = vim.v.lnum
        elseif vim.wo[vim.g.statusline_winid].relativenumber then
            number = vim.v.relnum
        end
        if number then
            return string.format("%" .. ((vim.v.relnum == 0) and "-" or "") .. width .. "d", number)
        end
        return string.rep(" ", width)
    end,
    hl = function ()
        if vim.v.relnum == 0 and vim.wo[vim.g.statusline_winid].relativenumber then
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

return M
