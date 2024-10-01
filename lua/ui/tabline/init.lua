if false and not nixCats("ui.tabline") then
    return
end

local utils = require("utils")
local hl = utils.compose_hl

local builder = require("ui.linebuilder")
local part = builder.part

function _G.click_handlers.goto_buffer(buf)
    local win = vim.iter(vim.api.nvim_tabpage_list_wins(0)):find(function (win)
        return vim.api.nvim_win_get_buf(win) == buf
    end)
    if win then
        vim.api.nvim_set_current_win(win)
    else
        vim.api.nvim_set_current_buf(buf)
    end
end

function _G.click_handlers.close_buffer(buf)
    vim.api.nvim_buf_delete(buf, {})
    vim.cmd("redrawtabline")
end

local M = {}

function M.buffer(buf)
    local filename = vim.fn.fnamemodify(vim.fn.bufname(buf), ":t")
    if filename == "" then
        filename = "[No Name]"
    end

    local cur_str = (vim.api.nvim_get_current_buf() == buf) and "Current" or ""
    local diagnostic_str = ""

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

    local signs = {
        error = get_sign("DiagnosticSignError", "E", "TblDiagnosticError"),
        warn = get_sign("DiagnosticSignWarn", "W", "TblDiagnosticWarn"),
        info = get_sign("DiagnosticSignInfo", "I", "TblDiagnosticInfo"),
        hint = get_sign("DiagnosticSignHint", "H", "TblDiagnosticHint"),
    }

    local diagnostics = {}
    if errors > 0 then
        table.insert(diagnostics,
            part(string.format("%d %s", errors, utils.utf8sub(signs.error.text, 1, 1)), false, signs.error.texthl)
        )
    end
    if warnings > 0 then
        table.insert(diagnostics,
            part(string.format("%d %s", warnings, utils.utf8sub(signs.warn.text, 1, 1)), false, signs.warn.texthl))
    end
    if infos > 0 then
        table.insert(diagnostics,
            part(string.format("%d %s", infos, utils.utf8sub(signs.info.text, 1, 1)), false, signs.info.texthl))
    end
    if hints > 0 then
        table.insert(diagnostics,
            part(string.format("%d %s", hints, utils.utf8sub(signs.hint.text, 1, 1)), false, signs.hint.texthl))
    end


    local label = part(filename, { after = true }, string.format("Tbl%sFilename%s", cur_str, diagnostic_str),
        "v:lua.click_handlers.goto_buffer",
        tostring(buf))
    local close_button = part("󰖭", { before = true, after = true }, string.format("Tbl%sCloseButton", cur_str),
        "v:lua.click_handlers.close_buffer", tostring(buf))
    return part({ label, part(diagnostics, false), close_button }, { before = true },
        string.format("Tbl%sBuffer", cur_str))
end

function M.buffers()
    local tabpage_wins = vim.api.nvim_tabpage_list_wins(0)
    local buffers = vim.iter(vim.api.nvim_list_bufs()):filter(function (buf)
        local wins_with_buf = vim.fn.win_findbuf(buf)
        return vim.iter(wins_with_buf):any(function (win)
            return vim.list_contains(tabpage_wins, win)
        end)
    end):totable()
    buffers = vim.api.nvim_list_bufs()
    local parts = {
        part("Buffers", nil, "TblBufferLabel"),
    }
    for _, buf in ipairs(buffers) do
        if vim.fn.buflisted(buf) ~= 0 then
            table.insert(parts, M.buffer(buf))
        end
    end
    return part(parts, false, "CursorLine")
end

---Creates tab line format string
---@return string
function TabLine()
    local line = part({ 
        M.buffers(),
        part("%=", nil, "StlSectionC"),
    }, { before = false })
    return builder.part_to_str(line)
end

vim.api.nvim_set_hl(0, "TblBufferLabel", hl({ fg = "@method", bold = true, reverse = true }))

vim.api.nvim_set_hl(0, "TblBuffer", hl({ bg = "Visual" }))
vim.api.nvim_set_hl(0, "TblCloseButton", hl({ fg = "Error", bg = "TblBuffer" }))
vim.api.nvim_set_hl(0, "TblFilename", hl({ link = "TblBuffer", fg = "Normal" }))

vim.api.nvim_set_hl(0, "TblCurrentBuffer", hl({ fg = "@method", bg = "TblBuffer" }))
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



vim.o.tabline = "%!v:lua.TabLine()"
vim.o.showtabline = 2

vim.api.nvim_create_augroup("TablineRedraw", { clear = true })
vim.api.nvim_create_autocmd("DiagnosticChanged", {
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
