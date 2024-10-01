if not nixCats("ui.statusline") then
    return
end

local builder = require("ui.linebuilder")
local part = builder.part

local hl = require("utils").compose_hl

local stl = require("ui.statusline.common")
local git = require("ui.statusline.git")

---Creates status line format string
---@return string
function StatusLine()
    local line = part({
        part({ stl.mode() }, false, "StlSectionA"),
        part({
            git.all(),
            stl.filename(),
            stl.diagnostics(),
        }, nil, "StlSectionB"),
        part({}, nil, "StlSectionC"),
        part("%=", nil, "StlSectionC"),
        part({
            stl.filetype(),
            stl.encoding(),
        }, nil, "StlSectionB"),
        part({ stl.pos() }, nil, "StlSectionA"),
    }, false)
    return builder.part_to_str(line)
end

vim.api.nvim_set_hl(0, "StlSectionA", hl({ link = "@method", reverse = true }))
vim.api.nvim_set_hl(0, "StlSectionB", hl({ link = "Visual" }))
vim.api.nvim_set_hl(0, "StlSectionC", hl({ link = "Normal" }))

vim.api.nvim_set_hl(0, "StlModeNormal", hl({ link = "@method", reverse = true, bold = true }))
vim.api.nvim_set_hl(0, "StlModeVisual", hl({ link = "@keyword", reverse = true, bold = true }))
vim.api.nvim_set_hl(0, "StlModeInsert", hl({ link = "@string", reverse = true, bold = true }))
vim.api.nvim_set_hl(0, "StlModeReplace", hl({ link = "@character", reverse = true, bold = true }))
vim.api.nvim_set_hl(0, "StlModeCommand", hl({ link = "@constant", reverse = true, bold = true }))
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
