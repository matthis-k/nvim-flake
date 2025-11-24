local Snacks = require("snacks")

local function list_workspace_folders()
    vim.print(vim.lsp.buf.list_workspace_folders())
end


---@type table[]
local maps = {
    {
        mode = "n",
        lhs = "<C-w>o",
        rhs = function ()
            local bufnr = vim.api.nvim_get_current_buf()
            vim.api.nvim_feedkeys(vim.keycode("<C-w>o"), "n", false)
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if buf ~= bufnr then vim.api.nvim_buf_delete(buf, {}) end
            end
        end,
        opts = { desc = "Zoom window & wipe other buffers" },
    },
    { mode = "n", lhs = "<esc>",   rhs = "<cmd>noh<CR>", opts = { desc = "Clear search highlight" } },
    { mode = "t", lhs = "<c-esc>", rhs = "<C-\\><C-n>",  opts = { desc = "Leave terminal normal mode", silent = true } },
    {
        mode = "v",
        lhs = "/",
        rhs = function ()
            vim.cmd('normal! "*y')
            local sel = vim.fn.getreg("*")
            vim.cmd("/" .. vim.fn.escape(sel, "\\/.*$^~[]"))
            vim.api.nvim_feedkeys(vim.keycode("N"), "n", false)
        end,
        opts = { noremap = true, silent = true, desc = "Search for selected text" },
    },

    { mode = "n", lhs = "j", rhs = "gj", opts = { desc = "Down (wrap-aware)" } },
    { mode = "n", lhs = "k", rhs = "gk", opts = { desc = "Up   (wrap-aware)" } },

    { mode = "n", lhs = "<C-Left>", rhs = "<cmd>vertical resize -2<CR>", opts = { desc = "Narrow window" } },
    { mode = "n", lhs = "<C-Right>", rhs = "<cmd>vertical resize +2<CR>", opts = { desc = "Widen window" } },
    { mode = "n", lhs = "<C-Down>", rhs = "<cmd>resize -2<CR>", opts = { desc = "Shorten window" } },
    { mode = "n", lhs = "<C-Up>", rhs = "<cmd>resize +2<CR>", opts = { desc = "Taller window" } },

    { mode = "v", lhs = "<A-j>", rhs = ":m '>+1<CR>gv=gv", opts = { desc = "Move ↓ (block)" } },
    { mode = "v", lhs = "<A-k>", rhs = ":m '<-2<CR>gv=gv", opts = { desc = "Move ↑ (block)" } },
    { mode = "n", lhs = "<A-J>", rhs = "<cmd>m .+1<CR>==", opts = { desc = "Move ↓ (line)" } },
    { mode = "n", lhs = "<A-K>", rhs = "<cmd>m .-2<CR>==", opts = { desc = "Move ↑ (line)" } },
    { mode = "i", lhs = "<A-J>", rhs = "<Esc><cmd>m .+1<CR>==gi", opts = { desc = "Move ↓ (insert)" } },
    { mode = "i", lhs = "<A-K>", rhs = "<Esc><cmd>m .-2<CR>==gi", opts = { desc = "Move ↑ (insert)" } },

    { mode = { "n", "x", "o" }, lhs = "n", rhs = "'Nn'[v:searchforward]", opts = { expr = true, desc = "Next search result" } },
    { mode = { "n", "x", "o" }, lhs = "N", rhs = "'nN'[v:searchforward]", opts = { expr = true, desc = "Prev search result" } },

    { mode = "n", lhs = "H", rhs = "<cmd>bprevious<CR>", opts = { desc = "Prev buffer" } },
    { mode = "n", lhs = "L", rhs = "<cmd>bnext<CR>", opts = { desc = "Next buffer" } },
    { mode = "n", lhs = "gB", rhs = "<cmd>bprevious<CR>", opts = { desc = "Prev buffer" } },
    { mode = "n", lhs = "gb", rhs = "<cmd>bnext<CR>", opts = { desc = "Next buffer" } },

    { mode = "i", lhs = ",", rhs = ",<C-g>u", opts = { desc = "Comma (& undo-break)" } },
    { mode = "i", lhs = ".", rhs = ".<C-g>u", opts = { desc = "Dot   (& undo-break)" } },
    { mode = "i", lhs = ";", rhs = ";<C-g>u", opts = { desc = "Semi  (& undo-break)" } },

    { mode = "i", lhs = "<C-BS>", rhs = "<C-w>", opts = { desc = "Backspace word" } },

    { mode = "v", lhs = "<", rhs = "<gv", opts = { desc = "Indent left & keep selection" } },
    { mode = "v", lhs = ">", rhs = ">gv", opts = { desc = "Indent right & keep selection" } },

    { mode = "n", lhs = "<leader>t", rhs = function () Snacks.terminal() end, opts = { desc = "Toggle terminal" } },

    { mode = "n", lhs = "<leader><leader>", rhs = function () Snacks.picker.smart() end, opts = { desc = "Smart find files" } },

    { mode = "n", lhs = "<leader>bd", rhs = "<cmd>bdelete<cr>", opts = { desc = "Delete" } },
    { mode = "n", lhs = "<leader>bb", rhs = function () Snacks.picker.buffers() end, opts = { desc = "List" } },
    { mode = "n", lhs = "<leader>bl", rhs = function () Snacks.picker.buffers() end, opts = { desc = "List" } },
    { mode = "n", lhs = "<leader>b", rhs = "<nop>", opts = { desc = "Buffers" } },
    { mode = "n", lhs = "<leader>/", rhs = function () Snacks.picker.grep() end, opts = { desc = "Live grep" } },
    { mode = "n", lhs = "<leader>:", rhs = function () Snacks.picker.command_history() end, opts = { desc = "Command history" } },
    { mode = "n", lhs = "<leader>n", rhs = function () Snacks.notifier.show_history() end, opts = { desc = "Notification history" } },
    { mode = "n", lhs = "<leader><esc>", rhs = function () Snacks.notifier.hide() end, opts = { desc = "Dismiss notifications" } },
    { mode = "n", lhs = "<leader>e", rhs = function () Snacks.explorer() end, opts = { desc = "File explorer" } },

    { mode = { "n", "x" }, lhs = "<leader>o", rhs = "<nop>", opts = { desc = "OpenCode" } },

    { mode = { "n", "x" }, lhs = "<leader>f", rhs = "<nop>", opts = { desc = "Find" } },
    { mode = "n", lhs = "<leader>fD", rhs = function () Snacks.picker.diagnostics_buffer() end, opts = { desc = "Buffer diagnostics" } },
    { mode = "n", lhs = "<leader>fd", rhs = function () Snacks.picker.diagnostics() end, opts = { desc = "Diagnostics" } },
    { mode = "n", lhs = "<leader>fb", rhs = function () Snacks.picker.buffers() end, opts = { desc = "Buffers" } },
    { mode = "n", lhs = "<leader>ff", rhs = function () Snacks.picker.files() end, opts = { desc = "Find files" } },
    { mode = "n", lhs = "<leader>fg", rhs = function () Snacks.picker.git_files() end, opts = { desc = "Git files" } },
    { mode = "n", lhs = "<leader>fl", rhs = function () Snacks.picker.lines() end, opts = { desc = "Buffer lines" } },
    { mode = "n", lhs = "<leader>fm", rhs = function () Snacks.picker.marks() end, opts = { desc = "Marks" } },
    { mode = "n", lhs = "<leader>fp", rhs = function () Snacks.picker.projects() end, opts = { desc = "Projects" } },
    { mode = "n", lhs = "<leader>fR", rhs = function () Snacks.rename.rename_file() end, opts = { desc = "Rename file" } },
    { mode = "n", lhs = "<leader>fr", rhs = function () Snacks.picker.recent() end, opts = { desc = "Recent files" } },
    { mode = { "n", "x" }, lhs = "<leader>fW", rhs = function () Snacks.picker.grep_word() end, opts = { desc = "Search selection" } },
    { mode = "n", lhs = "<leader>fw", rhs = function () Snacks.picker.grep() end, opts = { desc = "Word" } },

    { mode = "n", lhs = "<leader>s", rhs = "<nop>", opts = { desc = "Search" } },
    { mode = "n", lhs = "<leader>sa", rhs = function () Snacks.picker.autocmds() end, opts = { desc = "Autocommands" } },
    { mode = "n", lhs = "<leader>sc", rhs = function () Snacks.picker.commands() end, opts = { desc = "Commands" } },
    { mode = "n", lhs = "<leader>sH", rhs = function () Snacks.picker.highlights() end, opts = { desc = "Highlights" } },
    { mode = "n", lhs = "<leader>sh", rhs = function () Snacks.picker.help() end, opts = { desc = "Help" } },
    { mode = "n", lhs = "<leader>si", rhs = function () Snacks.picker.icons() end, opts = { desc = "Icons" } },
    { mode = "n", lhs = "<leader>sk", rhs = function () Snacks.picker.keymaps() end, opts = { desc = "Keymaps" } },
    { mode = "n", lhs = "<leader>sm", rhs = function () Snacks.picker.man() end, opts = { desc = "Manpages" } },

    { mode = "n", lhs = "<leader>g", rhs = "<nop>", opts = { desc = "Git" } },
    { mode = "n", lhs = "<leader>gs", rhs = function () Snacks.picker.git_status() end, opts = { desc = "Git status" } },
    { mode = "n", lhs = "<leader>gb", rhs = function () Snacks.picker.git_branches() end, opts = { desc = "Git branches" } },
    { mode = "n", lhs = "<leader>gl", rhs = function () Snacks.picker.git_log() end, opts = { desc = "Git log" } },
    { mode = "n", lhs = "<leader>gL", rhs = function () Snacks.picker.git_log_line() end, opts = { desc = "Git log line" } },
    { mode = "n", lhs = "<leader>gd", rhs = function () Snacks.picker.git_diff() end, opts = { desc = "Git diff" } },
    { mode = "n", lhs = "<leader>gS", rhs = function () Snacks.picker.git_stash() end, opts = { desc = "Git stash" } },
    { mode = "n", lhs = "<leader>gi", rhs = function () Snacks.picker.gh_issue() end, opts = { desc = "GitHub issues" } },
    { mode = "n", lhs = "<leader>gI", rhs = function () Snacks.picker.gh_issue({ state = "all" }) end, opts = { desc = "All GitHub issues" } },
    { mode = "n", lhs = "<leader>gp", rhs = function () Snacks.picker.gh_pr() end, opts = { desc = "GitHub PRs" } },
    { mode = "n", lhs = "<leader>gP", rhs = function () Snacks.picker.gh_pr({ state = "all" }) end, opts = { desc = "All GitHub PRs" } },

    { mode = "n", lhs = "<leader>v", rhs = "<nop>", opts = { desc = "Vim" } },
    { mode = "n", lhs = "<leader>vd", rhs = function () Snacks.dashboard.open() end, opts = { desc = "Dashboard" } },
    { mode = "n", lhs = "<leader>vv", rhs = "<cmd>cd " .. nixCats.configDir .. " | e init.lua <CR>", opts = { desc = "Edit config" } },
    { mode = "n", lhs = "<leader>vc", rhs = require("theme.color_preview").toggle, opts = { desc = "Toggle color preview" } },
    { mode = "n", lhs = "<leader>vs", rhs = function () require("pick-resession").pick() end, opts = { desc = "Sessions" } },

    { mode = "n", lhs = "<leader>q", rhs = "<nop>", opts = { desc = "Quickfix" } },
    { mode = "n", lhs = "<leader>qj", rhs = "<cmd>cnext<CR>", opts = { desc = "Next quickfix", silent = true } },
    { mode = "n", lhs = "<leader>qk", rhs = "<cmd>cprev<CR>", opts = { desc = "Prev quickfix", silent = true } },
    { mode = "n", lhs = "<leader>l", rhs = "<nop>", opts = { desc = "Lsp" } },

    { mode = "n", lhs = "gl", rhs = vim.diagnostic.open_float, opts = { silent = true, desc = "Open diagnostics" } },
    { mode = "n", lhs = "<space>lk", rhs = function () vim.diagnostic.jump({ count = -1 }) end, opts = { silent = true, desc = "Go to prev diagnostic" } },
    { mode = "n", lhs = "<space>lj", rhs = function () vim.diagnostic.jump({ count = 1 }) end, opts = { silent = true, desc = "Go to next diagnostic" } },
    {
        mode = "n",
        lhs = "gra",
        rhs = vim.lsp.buf.code_action,
        opts = {
            silent = true,
            desc = "Code action",
            lsp = { method = "textDocument/codeAction" },
        },
    },
    {
        mode = "n",
        lhs = "gD",
        rhs = vim.lsp.buf.declaration,
        opts = {
            silent = true,
            desc = "Go to declaration",
            lsp = { method = "textDocument/declaration" },
        },
    },
    {
        mode = "n",
        lhs = "gd",
        rhs = function () Snacks.picker.lsp_definitions() end,
        opts = {
            silent = true,
            desc = "Go to definition",
            lsp = { method = "textDocument/definition" },
        },
    },
    {
        mode = "n",
        lhs = "K",
        rhs = vim.lsp.buf.hover,
        opts = {
            silent = true,
            desc = "Show hover information",
            lsp = { method = "textDocument/hover" },
        },
    },
    {
        mode = "n",
        lhs = "gri",
        rhs = function () Snacks.picker.lsp_implementations() end,
        opts = {
            silent = true,
            desc = "Go to implementation",
            lsp = { method = "textDocument/implementation" },
        },
    },
    {
        mode = "n",
        lhs = "<space>li",
        rhs = function ()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
        end
        ,
        opts = {
            silent = true,
            desc = "Toggle inlay hints",
            lsp = { method = "textDocument/inlayHint" },
        },
    },
    {
        mode = "n",
        lhs = "grr",
        rhs = function () Snacks.picker.lsp_references() end,
        opts = {
            silent = true,
            desc = "Find references",
            lsp = { method = "textDocument/references" },
        },
    },
    {
        mode = "n",
        lhs = "grn",
        rhs = vim.lsp.buf.rename,
        opts = {
            silent = true,
            desc = "Rename symbol",
            lsp = { method = "textDocument/rename" },
        },
    },
    {
        mode = "n",
        lhs = "grd",
        rhs = function () Snacks.picker.lsp_type_definitions() end,
        opts = {
            silent = true,
            desc = "Go to type definition",
            lsp = { method = "textDocument/typeDefinition" },
        },
    },
    {
        mode = "n",
        lhs = "<leader>lw",
        rhs = "<nop>",
        opts = {
            desc = "Workspace",
            lsp = { method = "workspace/workspaceFolders" },
        },
    },
    {
        mode = "n",
        lhs = "<space>lwa",
        rhs = vim.lsp.buf.add_workspace_folder,
        opts = {
            silent = true,
            desc = "Add folder",
            lsp = { method = "workspace/workspaceFolders" },
        },
    },
    {
        mode = "n",
        lhs = "<space>lwr",
        rhs = vim.lsp.buf.remove_workspace_folder,
        opts = {
            silent = true,
            desc = "Remove folder",
            lsp = { method = "workspace/workspaceFolders" },
        },
    },
    {
        mode = "n",
        lhs = "<space>lwl",
        rhs = list_workspace_folders,
        opts = {
            silent = true,
            desc = "List folders",
            lsp = { method = "workspace/workspaceFolders" },
        },
    },
}

return {
    leader = " ",
    maps = maps,
}
