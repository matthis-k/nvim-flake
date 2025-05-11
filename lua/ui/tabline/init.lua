local utils       = require("utils")

local Part        = require("part")
local Builder     = Part.Builder

_G.click_handlers = _G.click_handlers or {}

---@diagnostic disable-next-line: duplicate-set-field,unused-local
function _G.click_handlers.click_buffer(minwid, _num_clicks, _btn, _mods)
    local buf = tonumber(minwid)
    local win = vim.iter(vim.api.nvim_tabpage_list_wins(0))
        :find(function (w) return vim.api.nvim_win_get_buf(w) == buf end)
    if win then
        vim.api.nvim_set_current_win(win)
    else
        vim.api.nvim_set_current_buf(buf)
    end
end

---@diagnostic disable-next-line: duplicate-set-field,unused-local
function _G.click_handlers.click_close_buffer(minwid, _num_clicks, _btn, _mods)
    local buf = tonumber(minwid)
    if buf and vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = false })
        vim.cmd.redrawtabline()
    end
end

---@diagnostic disable-next-line: duplicate-set-field,unused-local
function _G.click_handlers.click_tab(minwid, _num_clicks, _btn, _mods)
    local tp = tonumber(minwid)
    if tp and vim.api.nvim_tabpage_is_valid(tp) then
        vim.api.nvim_set_current_tabpage(tp)
    end
end

---@diagnostic disable-next-line: duplicate-set-field,unused-local
function _G.click_handlers.click_close_tab(minwid, _num_clicks, _btn, _mods)
    local tp = tonumber(minwid)
    if tp and vim.api.nvim_tabpage_is_valid(tp) then
        vim.cmd("tabclose " .. vim.api.nvim_tabpage_get_number(tp))
        vim.cmd.redrawtabline()
    end
end

local function get_sign(name, fallback, texthl)
    local sign  = vim.fn.sign_getdefined(name)[1] or {}
    sign.text   = (sign.text ~= "") and sign.text or fallback
    sign.texthl = (sign.texthl ~= "") and sign.texthl or texthl
    return sign
end

local M = {}

---@param buf integer
function M.buffer(buf)
    local cur   = (vim.api.nvim_get_current_buf() == buf)
    local fname = vim.fn.fnamemodify(vim.fn.bufname(buf), ":t")
    if fname == "" then fname = "[No Name]" end

    return Builder({
        before   = " ",
        hl       = cur and "TblCurrentBuffer" or "TblBuffer",
        children = {
            Builder({ text = fname, hl = cur and "TblCurrentFilename" or "TblFilename" }),

            Builder({
                before    = " ",
                child_sep = " ",
                children  = function ()
                    local out = {}
                    local severities = {
                        { sev = vim.diagnostic.severity.ERROR, name = "DiagnosticSignError", sym = "E", hl = "DiagnosticError" },
                        { sev = vim.diagnostic.severity.WARN,  name = "DiagnosticSignWarn",  sym = "W", hl = "DiagnosticWarn" },
                        { sev = vim.diagnostic.severity.INFO,  name = "DiagnosticSignInfo",  sym = "I", hl = "DiagnosticInfo" },
                        { sev = vim.diagnostic.severity.HINT,  name = "DiagnosticSignHint",  sym = "H", hl = "DiagnosticHint" },
                    }
                    for _, s in ipairs(severities) do
                        local n = #vim.diagnostic.get(buf, { severity = s.sev })
                        if n > 0 then
                            local sign = get_sign(s.name, s.sym)
                            table.insert(out,
                                Builder({
                                    text = string.format("%d %s", n, utils.utf8sub(sign.text, 1, 1)),
                                    hl = (cur and "TblCurrent" or "Tbl") .. s.hl,
                                }))
                        end
                    end
                    return out
                end,
            }),

            Builder({
                text           = "󰖭",
                before         = " ",
                after          = " ",
                hl             = cur and "TblCurrentCloseButton" or "TblCloseButton",
                on_click       = "v:lua.click_handlers.click_close_buffer",
                on_click_param = tostring(buf),
            }),
        },
    })
end

M.buffers = Builder({
    hl        = "TblSectionC",
    child_sep = " ",
    children  = {
        Builder({
            text = "Buffers",
            hl = function () return require("ui.statusline").mode_info().hl end,
            before = " ",
            after =
            " ",
        }),
        Builder({
            children = function ()
                local kids = {}
                for _, b in ipairs(vim.api.nvim_list_bufs()) do
                    if vim.fn.buflisted(b) ~= 0 and vim.bo[b].filetype ~= "qf" then
                        table.insert(kids, M.buffer(b))
                    end
                end
                return kids
            end,
            child_sep = " ",
        }),
    },
})

---@param tp integer
function M.tab(tp)
    local cur = (vim.fn.tabpagenr() == tp)
    local tab_hl = cur and "TblCurrentTab" or "TblTab"
    local num_hl = tab_hl

    return Builder({
        before   = " ",
        hl       = tab_hl,
        children = {
            Builder({
                text           = tostring(tp),
                hl             = num_hl,
                on_click       = "v:lua.click_handlers.click_tab",
                on_click_param = tostring(tp),
            }),
            Builder({
                text           = "󰖭",
                before         = " ",
                after          = " ",
                hl             = cur and "TblCurrentTabCloseButton" or "TblTabCloseButton",
                on_click       = "v:lua.click_handlers.click_close_tab",
                on_click_param = tostring(tp),
            }),
        },
    })
end

M.tabs = Builder({
    hl        = "TblSectionC",
    child_sep = " ",
    children  = {
        Builder({
            children = function ()
                local kids = {}
                for _, tp in ipairs(vim.api.nvim_list_tabpages()) do
                    table.insert(kids, M.tab(tp))
                end
                return kids
            end,
            child_sep = " ",
        }),
        Builder({
            text = "Tabs",
            hl = function () return require("ui.statusline").mode_info().hl end,
            before = " ",
            after =
            " ",
        }),
    },
})

M.whole = Builder({
    children = {
        M.buffers,
        Builder({ text = "%=" }),
        M.tabs,
    },
})

return M
