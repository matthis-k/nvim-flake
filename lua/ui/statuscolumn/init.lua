local utf8sub = require("utils").utf8sub
local foldexpr = require("utils").foldexpr
local Part = require("ui.lib.linepart")

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

function M.init_window_cache(win)
    local win_cache = {}
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
    local ns_ids = vim.api.nvim_get_namespaces()
    for line = win_cache.first_line, win_cache.last_line do
        win_cache.lines[line] = {}
        for _, ns_id in pairs(ns_ids) do
            win_cache.lines[line][ns_id] = {}
        end
    end

    for _, ns_id in pairs(ns_ids) do
        for _, sign in ipairs(vim.api.nvim_buf_get_extmarks(
            buf, ns_id,
            { win_cache.first_line - 1, 0 },
            { win_cache.last_line - 1, -1 },
            { type = "sign", details = true }
        )) do
            table.insert(win_cache.lines[sign[2] + 1][ns_id], sign)
        end
    end

    local empty_ns_lines = {}
    for line = win_cache.first_line, win_cache.last_line do
        for _, ns_id in pairs(ns_ids) do
            local ns_cache = win_cache.lines[line][ns_id]
            empty_ns_lines[ns_id] = empty_ns_lines[ns_id] or 0
            if #ns_cache == 0 then
                empty_ns_lines[ns_id] = empty_ns_lines[ns_id] + 1
            end
        end
    end
    win_cache.ns_empty = {}
    for _, ns_id in pairs(ns_ids) do
        local visible_lines = win_cache.last_line - win_cache.first_line + 1
        local is_ns_emtpy = empty_ns_lines[ns_id] >= visible_lines
        win_cache.ns_empty[ns_id] = is_ns_emtpy
    end
    win_cache.ns_ids = ns_ids

    local infos = {}
    for line = win_cache.first_line, win_cache.last_line do
        local fi = foldexpr(line, win)
        infos[line] = fi
    end
    local cursor_info = infos[win_cache.cursor_line]

    win_cache.folds = {
        infos = infos,
        current = {
            first = cursor_info.start,
            last = win_cache.cursor_line,
            level = cursor_info and cursor_info.level or 0,
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
        local text = string.rep(" ", shared.win_cache.numberwidth or 0)
        if vim.v.virtnum == 0 and shared.win_cache.numberwidth and shared.win_cache.numberwidth > 0 then
            local number
            if vim.wo[shared.win].number and vim.wo[shared.win].relativenumber then
                number = (vim.v.relnum == 0) and vim.v.lnum or vim.v.relnum
            elseif vim.wo[shared.win].number then
                number = vim.v.lnum
            elseif vim.wo[shared.win].relativenumber then
                number = vim.v.relnum
            end
            if number then
                text = string.format("%" .. ((vim.v.relnum == 0) and "-" or "") .. shared.win_cache.numberwidth .. "d",
                    number)
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
    :name("number_column")

local fold_column = Part()
    ---@diagnostic disable-next-line: unused-local
    :cache(function (lcache, shared)
        local win_cache = shared.win_cache
        local lnum = vim.v.lnum
        local fillchars = vim.opt.fillchars:get()
        local char_closed = fillchars.foldclose or "+"
        local char_open = fillchars.foldopen or "-"
        local char_sep = fillchars.foldsep or " "

        local info = win_cache and win_cache.folds and win_cache.folds.infos and win_cache.folds.infos[lnum]
        local current = win_cache and win_cache.folds and win_cache.folds.current

        local text = " "
        local hl = "StcFold"

        if info and info.level >= 1 then
            local is_start = info.start == lnum
            local is_closed = info.lines > 0
            if is_start then
                text = is_closed and char_closed or char_open
            else
                text = char_sep
            end

            if current and current.level >= 1 and lnum >= current.first and lnum <= current.last then
                hl = "StcFoldCurrent"
            end
        end
        lcache.text = text
        lcache.hl = hl
    end)
    :text(function (lcache) return lcache.text end)
    :hl(function (lcache) return lcache.hl end)
    :on_click("v:lua.click_handlers.click_fold")
    :name("fold_column")

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
            local ns_ids = vim.iter(shared.win_cache.ns_ids or vim.api.nvim_get_namespaces())
                :map(function (name, id)
                    if (lcache.filter == nil) or lcache.filter(name) then return id end
                end)
                :totable()
            if hide_empty and vim.iter(ns_ids):all(function (ns_id)
                    return shared.win_cache.ns_empty and shared.win_cache.ns_empty[ns_id] and
                        shared.win_cache.ns_empty[ns_id]
                end) then
                width = 0
            end
            local extmarks = vim.iter(ns_ids)
                :map(function (ns_id)
                    return shared.win_cache.lines and shared.win_cache.lines[vim.v.lnum] and
                        shared.win_cache.lines[vim.v.lnum][ns_id]
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


M.whole = Part():cache(function (_, shared)
    shared.win = vim.g.statusline_winid
    shared.win_cache = cache[shared.win]
end):children({
    signs({
        filter = function (name)
            return not (name:match("vim%.lsp%..+%..+[%.%/]diagnostic[%.%/]signs")
                or name:match("gitsigns_signs.*"))
        end,
        hide_empty = true,
    }):name("other_signs"),
    signs({ filter = function (name) return name:match("vim%.lsp%..+%..+[%.%/]diagnostic[%.%/]signs") end }):name(
        "lsp_signs"),
    fold_column,
    number_column,
    signs({
        filter = function (name) return name:match("gitsigns_signs_.*") end,
        width = 1,
    }):name("git_signs"),
}):name("whole")

M.init_cache()
return M
