if not nixCats("ui.statusline") then
    return
end

local stl = require("ui.statusline")

---Creates status line format string
---@return string
function StatusLine()
    return stl.whole:eval()
end

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
