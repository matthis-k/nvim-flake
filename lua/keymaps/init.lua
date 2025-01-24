local map = vim.keymap.set

map("n", "<c-w>o", function ()
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_feedkeys(vim.keycode("<c-w>o"), "n", false)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if buf ~= bufnr then
            vim.api.nvim_buf_delete(buf, {})
        end
    end
end)

map("n", "<esc>", "<cmd>noh<cr>")

map("v", "/", function ()
    vim.cmd('normal! "*y')
    local selected_text = vim.fn.getreg("*")
    vim.cmd("/" .. vim.fn.escape(selected_text, "\\/.*$^~[]"))
    vim.api.nvim_feedkeys(vim.keycode("N"), "n", false)
end, { noremap = true, silent = true })

map("n", "j", "gj")
map("n", "k", "gk")

map("n", "<c-left>", "<cmd>vertical resize -2<cr>")
map("n", "<c-down>", "<cmd>resize -2<cr>")
map("n", "<c-up>", "<cmd>resize +2<cr>")
map("n", "<c-right>", "<cmd>vertical resize +2<cr>")

map("v", "<a-j>", ":m '>+1<cr>gv=gv", { desc = "Move down" })
map("v", "<a-k>", ":m '<-2<cr>gv=gv", { desc = "Move up" })
map("n", "<a-J>", "<cmd>m .+1<cr>==", { desc = "Move down" })
map("n", "<a-K>", "<cmd>m .-2<cr>==", { desc = "Move up" })
map("i", "<a-J>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move down" })
map("i", "<a-K>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move up" })

map({ "n", "x", "o" }, "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next search result" })
map({ "n", "x", "o" }, "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev search result" })

map("n", "H", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "L", "<cmd>bnext<cr>", { desc = "Next buffer" })

map("n", "gB", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "gb", "<cmd>bnext<cr>", { desc = "Next buffer" })

map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

map("i", "<c-bs>", "<c-w>")

map("v", "<", "<gv")
map("v", ">", ">gv")

map("n", "<leader>vc", "<cmd>cd " .. nixCats.configDir .. " | e init.lua <cr>", { desc = "Config" })
