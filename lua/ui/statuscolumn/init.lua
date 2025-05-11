local utf8sub = require("utils").utf8sub
local foldexpr = require("utils").foldexpr
local Part = require("part")
local Builder = Part.Builder

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
    end

    local extmarks = vim.api.nvim_buf_get_extmarks(
        buf, -1,
        { win_cache.first_line - 1, 0 },
        { win_cache.last_line - 1, -1 },
        { details = true, type = "sign" }
    )
    local ns_reverse = {}
    for name, id in pairs(ns_ids) do
        ns_reverse[id] = name
    end
    win_cache.ns_reverse = ns_reverse
    local ns_populated = {}

    for _, extmark in ipairs(extmarks) do
        local id, lnum, col, details = extmark[1], extmark[2] + 1, extmark[3], extmark[4]
        table.insert(win_cache.lines[lnum], { id = id, col = col, lnum = lnum, details = details })
        ns_populated[details.ns_id] = ns_populated[details.ns_id] ~= false
    end

    win_cache.ns_ids = ns_ids
    win_cache.ns_populated = ns_populated

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

    local number_column = Builder({
        ---@param self Part.instance
        ---@return string
        build_string = function (self)
            local lnum = self.args.lnum
            local text = string.rep(" ", win_cache.numberwidth or 0)
            if vim.v.virtnum == 0 and win_cache.numberwidth and win_cache.numberwidth > 0 then
                local number
                if vim.wo[vim.g.statusline_winid].number and vim.wo[vim.g.statusline_winid].relativenumber then
                    number = (vim.v.relnum == 0) and lnum or vim.v.relnum
                elseif vim.wo[vim.g.statusline_winid].number then
                    number = lnum
                elseif vim.wo[vim.g.statusline_winid].relativenumber then
                    number = vim.v.relnum
                end
                if number then
                    text = string.format(
                        "%" .. ((vim.v.relnum == 0) and "-" or "") .. win_cache.numberwidth .. "d",
                        number)
                end
            end
            self.text = text

            if vim.v.relnum == 0 and vim.wo[vim.g.statusline_winid].relativenumber then
                self.hl = "StcCurrentLineNumber"
            else
                self.hl = "StcLineNumber"
            end
            return Part.Instance.build_string(self, nil)
        end,
        on_click = "v:lua.click_handlers.click_line",
    })

    local fold_column = Part.Builder({
        build_string = function (self)
            local fillchars = vim.opt.fillchars:get()
            local char_closed = fillchars.foldclose or "+"
            local char_open = fillchars.foldopen or "-"
            local char_sep = fillchars.foldsep or " "
            local lnum = vim.v.lnum

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
            self.text = text
            self.hl = hl
            return Part.Instance.build_string(self)
        end,
        on_click = "v:lua.click_handlers.click_fold",
    })

    win_cache.placed_signs = {}
    local sign_col_id = 0

    local function signs(opts)
        sign_col_id = sign_col_id + 1
        local col_id = sign_col_id
        win_cache.placed_signs[col_id] = {}

        return Part.Builder({
            ctx = function (args)
                local lnum = args.lnum
                local extmark = vim.iter(win_cache.lines[lnum] or {})
                    :filter(function (mark)
                        local ns = win_cache.ns_reverse[mark.details.ns_id]
                        return ((not opts.filter) or opts.filter(ns))
                            and mark.details.sign_text
                    end)
                    :fold(nil, function (acc, cur)
                        if not acc
                            or acc.details.priority < cur.details.priority
                            or (acc.details.priority == cur.details.priority
                                and acc.details.ns_id < cur.details.ns_id) then
                            acc = cur
                        end
                        return acc
                    end)
                win_cache.placed_signs[col_id][lnum] = extmark ~= nil
                return extmark
            end,
            build_string = function (self)
                local width = opts.width or 2
                local fill_char = opts.fill_char or " "
                local extmark = self.ctx
                local text = extmark and utf8sub(extmark.details.sign_text, 1, width)
                    or fill_char:rep(width)

                self.hl = extmark and extmark.details.sign_hl_group or nil
                self.text = (opts.auto_hide and win_cache.empty_sign_columns[col_id])
                    and "" or text
            end,
        })
    end

    local builder = Builder({
        children = {
            signs({
                filter = function (name)
                    return not (name:find("diagnostic%.signs")
                        or name:match("gitsigns_signs.*"))
                end,
                auto_hide = true,
            }),
            signs({
                filter = function (name) return name:match("diagnostic%.signs") end,
            }),
            fold_column,
            number_column,
            signs({ filter = function (name) return name:match("gitsigns_signs_.*") end, width = 1 }),
        },
    })

    win_cache.instances = {}
    win_cache.empty_sign_columns = {}

    for i = win_cache.first_line, win_cache.last_line do
        local l = i
        win_cache.instances[i] = builder:instanciate({ lnum = l })
    end
    for i = 1, sign_col_id do
        local has_sign = false
        for _, v in pairs(win_cache.placed_signs[i]) do
            if v then
                has_sign = true
                break
            end
        end
        if not has_sign then
            win_cache.empty_sign_columns[i] = true
        end
    end

    return win_cache
end

_G.click_handlers = _G.click_handlers or {}
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
    local fold_info = foldexpr(lnum, win)

    if fold_info.start == lnum then
        if vim.fn.foldclosed(lnum) == -1 then
            vim.cmd(lnum .. "foldclose")
        else
            vim.cmd(lnum .. "foldopen")
        end
    else
        vim.api.nvim_win_set_cursor(win, { lnum, 0 })
    end
end

function M.get(win, line)
    return cache[win] and cache[win].instances and cache[win].instances[line]
end

return M
