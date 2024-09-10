if not nixCats("sessions") then
    return
end

local resession = require("resession")

resession.setup({})

vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function ()
        resession.save(vim.fn.getcwd(), { notify = true })
    end,
})
