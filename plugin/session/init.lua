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

vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lcount = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lcount then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
})
