if not nixCats("ui.tabline") then
    return
end

local tabline = require("ui.tabline")

---@return string
function TabLine()
    return tabline.whole:instanciate():build_string()
end

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
