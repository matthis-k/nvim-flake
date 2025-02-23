if not nixCats("ui.tabline") then
    return
end

local utils = require("utils")
local hl = utils.compose_hl

local Part = require("ui.lib.linepart")

function _G.click_handlers.click_buffer(minwid, num_clicks, btn, mods)
    local buf = minwid
    local win = vim.iter(vim.api.nvim_tabpage_list_wins(0)):find(function (win)
        return vim.api.nvim_win_get_buf(win) == buf
    end)
    if win then
        vim.api.nvim_set_current_win(win)
    else
        vim.api.nvim_set_current_buf(buf)
    end
end

function _G.click_handlers.click_close_buffer(minwid, num_clicks, btn, mods)
    local buf = minwid
    vim.api.nvim_buf_delete(buf, {})
    vim.cmd("redrawtabline")
end

function _G.click_handlers.click_tab(minwid, num_clicks, btn, mods)
    local tabpage = tonumber(minwid)
    if tabpage and vim.api.nvim_tabpage_is_valid(tabpage) then
        vim.api.nvim_set_current_tabpage(tabpage)
    end
end

function _G.click_handlers.click_close_tab(minwid, num_clicks, btn, mods)
    local tabpage = tonumber(minwid)
    if tabpage and vim.api.nvim_tabpage_is_valid(tabpage) then
        local tabpage_num = vim.api.nvim_tabpage_get_number(tabpage)
        vim.cmd("tabclose " .. tabpage_num)
    end
    vim.cmd("redrawtabline")
end

function _G.click_handlers.click_buffer(buf)
    local win = vim.iter(vim.api.nvim_tabpage_list_wins(0)):find(function (win)
        return vim.api.nvim_win_get_buf(win) == buf
    end)
    if win then
        vim.api.nvim_set_current_win(win)
    else
        vim.api.nvim_set_current_buf(buf)
    end
end

function _G.click_handlers.click_close_buffer(buf)
    vim.api.nvim_buf_delete(buf, {})
    vim.cmd("redrawtabline")
end

local M = {}

function M.buffer(buf)
    local filename = vim.fn.fnamemodify(vim.fn.bufname(buf), ":t")
    if filename == "" then
        filename = "[No Name]"
    end

    local errors = #vim.diagnostic.get(buf, { severity = vim.diagnostic.severity.ERROR })
    local warnings = #vim.diagnostic.get(buf, { severity = vim.diagnostic.severity.WARN })
    local infos = #vim.diagnostic.get(buf, { severity = vim.diagnostic.severity.INFO })
    local hints = #vim.diagnostic.get(buf, { severity = vim.diagnostic.severity.HINT })

    local function get_sign(sign_name, default_text, default_hl)
        local sign = vim.fn.sign_getdefined(sign_name)[1]
        sign.texthl = default_hl
        sign.text = sign.text or default_text
        return sign
    end

    return Part():cache(function (lcache, shared)
            shared.buf_cur_str = shared.buf_cur_str or {}
            shared.buf_cur_str[buf] = (vim.api.nvim_get_current_buf() == buf) and "Current" or ""
        end)
        :children({ Part():text(filename):hl(function (lcache, shared)
            return string.format("Tbl%sFilename", shared.buf_cur_str[buf])
        end),
            Part():children(
                function (lcache, shared)
                    local signs = {
                        error = get_sign("DiagnosticSignError", "E",
                            "Tbl" .. shared.buf_cur_str[buf] .. "DiagnosticError"),
                        warn = get_sign("DiagnosticSignWarn", "W", "Tbl" .. shared.buf_cur_str[buf] .. "DiagnosticWarn"),
                        info = get_sign("DiagnosticSignInfo", "I", "Tbl" .. shared.buf_cur_str[buf] .. "DiagnosticInfo"),
                        hint = get_sign("DiagnosticSignHint", "H", "Tbl" .. shared.buf_cur_str[buf] .. "DiagnosticHint"),
                    }
                    local diagnostics = {}
                    if errors > 0 then
                        table.insert(diagnostics,
                            Part(string.format("%d %s", errors, utils.utf8sub(signs.error.text, 1, 1))):hl(signs.error
                                .texthl)
                        )
                    end
                    if warnings > 0 then
                        table.insert(diagnostics,
                            Part(string.format("%d %s", warnings, utils.utf8sub(signs.warn.text, 1, 1))):hl(signs.warn
                                .texthl))
                    end
                    if infos > 0 then
                        table.insert(diagnostics,
                            Part(string.format("%d %s", infos, utils.utf8sub(signs.info.text, 1, 1))):hl(signs.info
                                .texthl))
                    end
                    if hints > 0 then
                        table.insert(diagnostics,
                            Part(string.format("%d %s", hints, utils.utf8sub(signs.hint.text, 1, 1))):hl(signs.hint
                                .texthl))
                    end
                    return diagnostics
                end
            ):child_sep(" "):before(" "),
            Part("󰖭"):before(" "):after(" "):hl(function (lcache, shared)
                return string.format(
                    "Tbl%sCloseButton", shared.buf_cur_str[buf])
            end)
                :on_click("v:lua.click_handlers.click_close_buffer", buf) })
        :before(" ")
        :hl(function (lcache, shared) return string.format("Tbl%sBuffer", shared.buf_cur_str[buf]) end)
end

local mode = require("ui.statusline.common").mode
M.buffers = Part():hl("TblSectionC"):children({
        Part("Buffers"):cache(mode.data.cache):hl(mode.data.hl):before(" "):after(" "),
        Part():hl("TblSectionC"):children(function (lcache, shared)
            local tabpage_wins = vim.api.nvim_tabpage_list_wins(0)
            local buffers = vim.api.nvim_list_bufs()
            local children = {}
            for _, buf in ipairs(buffers) do
                if vim.fn.buflisted(buf) ~= 0 then
                    table.insert(children, M.buffer(buf))
                end
            end
            return children
        end
        ):child_sep(" "),
    })

function M.tab(tabpage)
    return Part()
        :before(" ")
        :cache(function (_, shared)
            shared.tabpage_cur_str = (vim.fn.tabpagenr() == tabpage) and "Current" or ""
        end)
        :children({
            Part()
                :text(tostring(tabpage))
                :hl(function (_, shared)
                    return string.format("Tbl%stab", shared.tabpage_cur_str)
                end)
                :on_click("v:lua.click_handlers.click_tab", tabpage),
            Part("󰖭")
                :before(" "):after(" ")
                :hl(function (_, shared)
                    return string.format("Tbl%sTabCloseButton", shared.tabpage_cur_str)
                end)
                :on_click("v:lua.click_handlers.click_close_tab", tabpage),
        }):hl(function (_, shared)
            return string.format("Tbl%sTab", shared.tabpage_cur_str)
        end)
end

M.tabs = Part()
    :children({
        Part():after(" "):children(
            function ()
                local tabpages = vim.api.nvim_list_tabpages()
                local children = {}
                for _, tabpage in ipairs(tabpages) do
                    table.insert(children, M.tab(tabpage))
                end
                return children
            end
        ):child_sep(" "):hl("TblSectionC"),
        Part("Tabs"):cache(mode.data.cache):hl(mode.data.hl):before(" "):after(" "),
    })
    :hl("TblSectionC")

local line = Part():hl("TblSectionC"):children({
    M.buffers,
    Part("%="):hl("StlSectionC"),
     M.tabs,
})
---Creates tab line format string
---@return string
function TabLine()
    return line:eval()
end

vim.api.nvim_set_hl(0, "TblSectionA", hl({ link = "StlSectionA" }))
vim.api.nvim_set_hl(0, "TblSectionB", hl({ link = "StlSectionB" }))
vim.api.nvim_set_hl(0, "TblSectionC", hl({ link = "StlSectionC" }))

vim.api.nvim_set_hl(0, "TblBufferLabel", hl({ link = "TblSectionA", bold = true }))

vim.api.nvim_set_hl(0, "TblBuffer", hl({ link = "TblSectionB", bg = "StlSectionC" }))
vim.api.nvim_set_hl(0, "TblCloseButton", hl({ fg = "Error", bg = "TblBuffer" }))
vim.api.nvim_set_hl(0, "TblFilename", hl({ link = "TblBuffer", fg = "Normal" }))

vim.api.nvim_set_hl(0, "TblCurrentBuffer", hl({ link = "TblBuffer", bg = "Visual" }))
vim.api.nvim_set_hl(0, "TblCurrentFilename", hl({ fg = "@method", bg = "TblCurrentBuffer", bold = true }))
vim.api.nvim_set_hl(0, "TblCurrentCloseButton", hl({ bg = "TblCurrentBuffer", fg = "Error" }))

vim.api.nvim_set_hl(0, "TblDiagnosticError", hl({ fg = "DiagnosticError", bg = "TblBuffer", bold = true }))
vim.api.nvim_set_hl(0, "TblDiagnosticWarn", hl({ fg = "DiagnosticWarn", bg = "TblBuffer" }))
vim.api.nvim_set_hl(0, "TblDiagnosticInfo", hl({ fg = "DiagnosticInfo", bg = "TblBuffer" }))
vim.api.nvim_set_hl(0, "TblDiagnosticHint", hl({ fg = "DiagnosticHint", bg = "TblBuffer" }))

vim.api.nvim_set_hl(0, "TblCurrentDiagnosticError", hl({ fg = "DiagnosticError", bg = "TblCurrentBuffer", bold = true }))
vim.api.nvim_set_hl(0, "TblCurrentDiagnosticWarn", hl({ fg = "DiagnosticWarn", bg = "TblCurrentBuffer" }))
vim.api.nvim_set_hl(0, "TblCurrentDiagnosticInfo", hl({ fg = "DiagnosticInfo", bg = "TblCurrentBuffer" }))
vim.api.nvim_set_hl(0, "TblCurrentDiagnosticHint", hl({ fg = "DiagnosticHint", bg = "TblCurrentBuffer" }))

vim.api.nvim_set_hl(0, "TblTabLabel", hl({ link = "TblSectionA", bold = true }))

vim.api.nvim_set_hl(0, "TblTab", hl({ link = "TblSectionB", bg = "TblSectionC" }))
vim.api.nvim_set_hl(0, "TblTabCloseButton", hl({ fg = "Error", bg = "TblTab" }))

vim.api.nvim_set_hl(0, "TblCurrentTab", hl({ fg = "@method", bg = "TblSectionB", bold = true }))
vim.api.nvim_set_hl(0, "TblCurrentTabCloseButton", hl({ link = "TblTabCloseButton", bg = "TblCurrentTab" }))



vim.o.tabline = "%!v:lua.TabLine()"
vim.o.showtabline = 2

vim.api.nvim_create_augroup("TablineRedraw", { clear = true })
vim.api.nvim_create_autocmd({ "ModeChanged", "BufAdd", "BufDelete", "TabNew", "TabClosed", "DiagnosticChanged" }, {
    group = "TablineRedraw",
    pattern = "*",
    callback = function ()
        local buffers = vim.api.nvim_list_bufs()
        if #buffers > 0 then
            vim.cmd("redrawtabline")
        end
    end,
})

return M
