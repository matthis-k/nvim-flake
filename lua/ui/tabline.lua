local utls = require("utils")
local devicons = require("nvim-web-devicons")

local M = {}

local cache = {}

function M.init_cache()
    cache = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.fn.buflisted(buf) ~= 0 and vim.bo[buf].filetype ~= "qf" then
            local fname = vim.fn.fnamemodify(vim.fn.bufname(buf), ":t")
            if fname == "" then fname = "[No Name]" end

            local icon, icon_hl = devicons.get_icon(fname, vim.fn.fnamemodify(fname, ":e"), { default = true })

            cache[buf] = {
                cur = (vim.api.nvim_get_current_buf() == buf),
                fname = fname,
                icon = icon or "",
                icon_hl = icon_hl or "Normal",
            }
        end
    end
end

local function get_sign(name, fallback, texthl)
    local sign = vim.fn.sign_getdefined(name)[1] or {}
    sign.text = (sign.text ~= "") and sign.text or fallback
    sign.texthl = (sign.texthl ~= "") and sign.texthl or texthl
    return sign
end

function M.buffer(buf)
    return {
        name = "buffer",
        before = " ",
        hl = cache[buf].cur and "TblCurrentBuffer" or "TblBuffer",
        children = {
            {
                hl = utls.auto_hl({
                    bg = utls.to_hex(utls.highlights
                        [cache[buf].cur and "TblCurrentBuffer" or "TblBuffer"].bg),

                    fg = utls.to_hex(utls.highlights[cache[buf].icon_hl].fg),
                }),
                text = cache[buf].icon,
            },
            {
                before = " ",
                hl = cache[buf].cur and "TblCurrentFilename" or "TblFilename",
                text = cache[buf].fname,
                on_click = "v:lua.tbl_click_handlers.buffer",
                on_click_param = tostring(buf),
            },
            {
                before = " ",
                child_sep = " ",
                children = (function ()
                    local out = {}
                    local sev_cfg = {
                        { sev = vim.diagnostic.severity.ERROR, name = "DiagnosticSignError", sym = "E", hl = "DiagnosticError" },
                        { sev = vim.diagnostic.severity.WARN,  name = "DiagnosticSignWarn",  sym = "W", hl = "DiagnosticWarn" },
                        { sev = vim.diagnostic.severity.INFO,  name = "DiagnosticSignInfo",  sym = "I", hl = "DiagnosticInfo" },
                        { sev = vim.diagnostic.severity.HINT,  name = "DiagnosticSignHint",  sym = "H", hl = "DiagnosticHint" },
                    }
                    for _, s in ipairs(sev_cfg) do
                        local n = #vim.diagnostic.get(buf, { severity = s.sev })
                        if n > 0 then
                            local sign = get_sign(s.name, s.sym)
                            table.insert(out, {
                                text = string.format("%d %s", n, utls.utf8sub(sign.text, 1, 1)),
                                hl = (cache[buf].cur and "TblCurrent" or "Tbl") .. s.hl,
                            })
                        end
                    end
                    return out
                end)(),
            },
            {
                text = "󰖭",
                before = " ",
                after = " ",
                hl = cache[buf].cur and "TblCurrentCloseButton" or "TblCloseButton",
                on_click = "v:lua.tbl_click_handlers.close_buffer",
                on_click_param = tostring(buf),
            },
        },
    }
end

M.buffers = {
    name = "buffers",
    hl = "TblSectionC",
    child_sep = " ",
    children = {
        {
            text = "Buffers",
            hl = function () return require("ui.statusline").mode_info().hl end,
            before = " ",
            after = " ",
        },
        {
            hl = "TblSectionC",
            children = function ()
                local kids = {}
                for _, b in ipairs(vim.api.nvim_list_bufs()) do
                    if cache[b] then
                        table.insert(kids, M.buffer(b))
                    end
                end
                return kids
            end,
            child_sep = " ",
        },
    },
}

function M.tab(tp)
    local cur = (vim.fn.tabpagenr() == tp)
    local tab_hl = cur and "TblCurrentTab" or "TblTab"
    local num_hl = tab_hl

    return {
        name = "tab",
        before = " ",
        hl = tab_hl,
        children = {
            {
                text = tostring(tp),
                hl = num_hl,
                on_click = "v:lua.tbl_click_handlers.tab",
                on_click_param = tostring(tp),
            },
            {
                text = "󰖭",
                before = " ",
                after = " ",
                hl = cur and "TblCurrentTabCloseButton" or "TblTabCloseButton",
                on_click = "v:lua.tabl_click_handlers.close_tab",
                on_click_param = tostring(tp),
            },
        },
    }
end

M.tabs = {
    name = "tabs",
    hl = "TblSectionC",
    child_sep = " ",
    children = {
        {
            children = function ()
                local kids = {}
                for _, tp in ipairs(vim.api.nvim_list_tabpages()) do
                    table.insert(kids, M.tab(tp))
                end
                return kids
            end,
            child_sep = " ",
        },
        {
            text = "Tabs",
            hl = function () return require("ui.statusline").mode_info().hl end,
            before = " ",
            after = " ",
        },
    },
}

M.whole = {
    children = {
        M.buffers,
        { text = "%=" },
        M.tabs,
    },
}

_G.tbl_click_handlers = _G.tbl_click_handlers or {}
M.click_handlers = _G.tbl_click_handlers

---@diagnostic disable-next-line: unused-local
function M.click_handlers.buffer(minwid, _num_clicks, _btn, _mods)
    local buf = tonumber(minwid) or 0
    local win = vim.iter(vim.api.nvim_tabpage_list_wins(0))
        :find(function (w) return vim.api.nvim_win_get_buf(w) == buf end)
    if win then
        vim.api.nvim_set_current_win(win)
    else
        vim.api.nvim_set_current_buf(math.floor(buf))
    end
end

---@diagnostic disable-next-line: unused-local
function M.click_handlers.close_buffer(minwid, _num_clicks, _btn, _mods)
    local buf = tonumber(minwid)
    if buf and vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = false })
        vim.cmd.redrawtabline()
    end
end

---@diagnostic disable-next-line: unused-local
function M.click_handlers.tab(minwid, _num_clicks, _btn, _mods)
    local tp = tonumber(minwid)
    if tp and vim.api.nvim_tabpage_is_valid(tp) then
        vim.api.nvim_set_current_tabpage(tp)
    end
end

---@diagnostic disable-next-line: unused-local
function M.click_handlers.close_tab(minwid, _num_clicks, _btn, _mods)
    local tp = tonumber(minwid)
    if tp and vim.api.nvim_tabpage_is_valid(tp) then
        vim.cmd("tabclose " .. vim.api.nvim_tabpage_get_number(tp))
        vim.cmd.redrawtabline()
    end
end

return M
