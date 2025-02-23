if not nixCats("ui.statusline") then
    return
end

local Part = require("ui.lib.linepart")
local hl = require("utils").compose_hl

local stl = require("ui.statusline.common")
local git = require("ui.statusline.git")

local line = Part():children({
    stl.mode,
    Part():hl("StlSectionB"):before(" "):after(" "):children({
        git.all,
        stl.filename,
        Part():hl("StlSectionB"):before("["):after("]"):children({
            stl.modified,
            stl.readonly,
        }):child_sep(" "),
        stl.diagnostics,
    }):child_sep(" "),
    Part("%="):hl("StlSectionC"),
    Part():hl("StlSectionB"):before(" "):after(" "):children({
        stl.filetype,
        stl.encoding,
    }):child_sep(" "),
    Part():hl(function (_, shared) return shared.mode_hl end):before(" "):after(" "):children({
        stl.pos,
    }),
}):hl("StlSectionC")
---Creates status line format string
---@return string
function StatusLine()
    return line:eval()
end

vim.api.nvim_set_hl(0, "StlSectionA", hl({ fg = "@method", bg = "Normal", reverse = true }))
vim.api.nvim_set_hl(0, "StlSectionB", hl({ bg = "Visual" }))
vim.api.nvim_set_hl(0, "StlSectionC", hl({ link = "Normal" }))

vim.api.nvim_set_hl(0, "StlModeNormal", hl({ fg = "@method", bg = "Normal", reverse = true, bold = true }))
vim.api.nvim_set_hl(0, "StlModeVisual", hl({ fg = "@keyword", bg = "Normal", reverse = true, bold = true }))
vim.api.nvim_set_hl(0, "StlModeInsert", hl({ fg = "@string", bg = "Normal", reverse = true, bold = true }))
vim.api.nvim_set_hl(0, "StlModeReplace", hl({ fg = "@character", bg = "Normal", reverse = true, bold = true }))
vim.api.nvim_set_hl(0, "StlModeCommand", hl({ fg = "@constant", bg = "Normal", reverse = true, bold = true }))
vim.api.nvim_set_hl(0, "StlModeTerminalInsert", hl({ link = "StlModeInsert", reverse = true, bold = true }))
vim.api.nvim_set_hl(0, "StlModeTerminalNormal", hl({ link = "StlModeNormal", reverse = true, bold = true }))

vim.api.nvim_set_hl(0, "StlFilename", hl({ link = "Field" }))

vim.api.nvim_set_hl(0, "StlDiagnosticError", hl({ fg = "DiagnosticError", bg = "Visual", bold = true }))
vim.api.nvim_set_hl(0, "StlDiagnosticWarn", hl({ fg = "DiagnosticWarn", bg = "Visual" }))
vim.api.nvim_set_hl(0, "StlDiagnosticInfo", hl({ fg = "DiagnosticInfo", bg = "Visual" }))
vim.api.nvim_set_hl(0, "StlDiagnosticHint", hl({ fg = "DiagnosticHint", bg = "Visual" }))

vim.api.nvim_set_hl(0, "StlGitBranch", hl({ fg = "@method", bg = "StlSectionB", bold = true }))
vim.api.nvim_set_hl(0, "StlGitAdded", hl({ fg = "GitSignsAdd", bg = "StlSectionB" }))
vim.api.nvim_set_hl(0, "StlGitChanged", hl({ fg = "GitSignsChange", bg = "StlSectionB" }))
vim.api.nvim_set_hl(0, "StlGitDeleted", hl({ fg = "GitSignsDelete", bg = "StlSectionB" }))
vim.api.nvim_set_hl(0, "StlGitRemoteAhead", hl({ fg = "@class", bg = "StlSectionB" }))
vim.api.nvim_set_hl(0, "StlGitRemoteBehind", hl({ fg = "@class", bg = "StlSectionB" }))

vim.o.statusline = "%!v:lua.StatusLine()"
vim.o.laststatus = 3

vim.api.nvim_create_augroup("StlRedraw", { clear = true })
vim.api.nvim_create_autocmd({ "DiagnosticChanged", "ModeChanged" }, {
    group = "StlRedraw",
    callback = function ()
        local buffers = vim.api.nvim_list_bufs()
        if #buffers > 0 then
            vim.cmd("redrawstatus")
        end
    end,
})
