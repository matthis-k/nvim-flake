---@alias Mode string|string[]
---@alias Lhs  string
---@alias Rhs  (string|fun())
---@alias Opts table?

local function list_workspace_folders()
    vim.print(vim.lsp.buf.list_workspace_folders())
end

local function toggle_inlay_hints()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end

local with_telescope = nixCats("ui.telescope.enabled")

return {
    leader = " ",
    ---@type { [1]:Mode, [2]:Lhs, [3]:Rhs, [4]?:Opts }[]
    permanent = {
        { "n", "<C-w>o", function ()
            local bufnr = vim.api.nvim_get_current_buf()
            vim.api.nvim_feedkeys(vim.keycode("<C-w>o"), "n", false)
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if buf ~= bufnr then vim.api.nvim_buf_delete(buf, {}) end
            end
        end,
            { desc = "Zoom window & wipe other buffers" } },

        { "n", "<Esc>", "<cmd>noh<CR>", { desc = "Clear search highlight" } },

        { "v", "/", function ()
            vim.cmd('normal! "*y')
            local sel = vim.fn.getreg("*")
            vim.cmd("/" .. vim.fn.escape(sel, "\\/.*$^~[]"))
            vim.api.nvim_feedkeys(vim.keycode("N"), "n", false)
        end,
            { noremap = true, silent = true, desc = "Search for selected text" } },

        { "n", "j", "gj", { desc = "Down (wrap‑aware)" } },
        { "n", "k", "gk", { desc = "Up   (wrap‑aware)" } },

        { "n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Narrow window" } },
        { "n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Widen window" } },
        { "n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Shorten window" } },
        { "n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Taller window" } },

        { "v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move ↓ (block)" } },
        { "v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move ↑ (block)" } },
        { "n", "<A-J>", "<cmd>m .+1<CR>==", { desc = "Move ↓ (line)" } },
        { "n", "<A-K>", "<cmd>m .-2<CR>==", { desc = "Move ↑ (line)" } },
        { "i", "<A-J>", "<Esc><cmd>m .+1<CR>==gi", { desc = "Move ↓ (insert)" } },
        { "i", "<A-K>", "<Esc><cmd>m .-2<CR>==gi", { desc = "Move ↑ (insert)" } },

        { { "n",       "x",                        "o" }, "n", "'Nn'[v:searchforward]",
            { expr = true, desc = "Next search result" } },
        { { "n",       "x",                        "o" }, "N", "'nN'[v:searchforward]",
            { expr = true, desc = "Prev search result" } },

        { "n", "H", "<cmd>bprevious<CR>", { desc = "Prev buffer" } },
        { "n", "L", "<cmd>bnext<CR>", { desc = "Next buffer" } },
        { "n", "gB", "<cmd>bprevious<CR>", { desc = "Prev buffer" } },
        { "n", "gb", "<cmd>bnext<CR>", { desc = "Next buffer" } },

        { "i", ",", ",<C-g>u", { desc = "Comma (& undo‑break)" } },
        { "i", ".", ".<C-g>u", { desc = "Dot   (& undo‑break)" } },
        { "i", ";", ";<C-g>u", { desc = "Semi  (& undo‑break)" } },

        { "i", "<C-BS>", "<C-w>", { desc = "Backspace word" } },

        { "v", "<", "<gv", { desc = "Indent left & keep selection" } },
        { "v", ">", ">gv", { desc = "Indent right & keep selection" } },

        { "n", "<leader>e", function () require("tools.files.oil").open() end,
            { desc = "File explorer (oil)" } },

        { "n", "<leader>v",  "<nop>",                                      { desc = "Vim" } },
        { "n", "<leader>vv", "<cmd>cd " .. nixCats.configDir .. " | e init.lua <CR>",
            { desc = "Edit config" } },
        { "n", "<leader>vc", require("theme.color_preview").toggle,
            { desc = "Toggle color preview" } },

        { "n", "<leader>q",  "<nop>",                                      { desc = "Quickfix" } },
        { "n", "<leader>qj", "<cmd>cnext<CR>",                             { desc = "Next quickfix", silent = true } },
        { "n", "<leader>qk", "<cmd>cprev<CR>",                             { desc = "Prev quickfix", silent = true } },

        { "n", "gri",        vim.lsp.buf.implementation,                   { desc = "Go to implementation" } },
        { "n", "gra",        vim.lsp.buf.code_action,                      { desc = "Code action" } },
        { "n", "grr",        vim.lsp.buf.references,                       { desc = "Find references" } },
        { "n", "grn",        vim.lsp.buf.rename,                           { desc = "Rename symbol" } },

        { "n", "<leader>p",  "<nop>",                                      { desc = "Profiler" } },
        { "n", "<leader>pr", function () require("profiler"):report() end, { desc = "Report" } },
        { "n", "<leader>pp", function ()
            require("profiler"):toggle()
            vim.cmd.redrawstatus()
        end, { desc = "Toggle" } },
        { "n", "<leader>pc", function () require("profiler"):clean() end, { desc = "Clean" } },
    },

    ---@type table<string, { [1]:Mode, [2]:Lhs, [3]:Rhs, [4]?:Opts }[]>
    lsp_maps_by_capability = {
        ["textDocument/codeAction"] = {
            { "n", "gra", vim.lsp.buf.code_action, { silent = true, desc = "Code action" } },
        },
        ["textDocument/declaration*"] = {
            { "n", "gD", vim.lsp.buf.declaration, { silent = true, desc = "Go to declaration" } },
        },
        ["textDocument/definition"] = {
            { "n", "gd", with_telescope and "<cmd>Telescope lsp_definitions<cr>"
            or vim.lsp.buf.definition, { silent = true, desc = "Go to definition" } },
        },
        ["textDocument/formatting"] = {
            -- handled by conform
        },
        ["textDocument/hover"] = {
            { "n", "K", vim.lsp.buf.hover, { silent = true, desc = "Show hover information" } },
        },
        ["textDocument/implementation*"] = {
            { "n", "gri", with_telescope and "<cmd>Telescope lsp_implementations<cr>"
            or vim.lsp.buf.implementation, { silent = true, desc = "Go to implementation" } },
        },
        ["textDocument/inlayHint"] = {
            { "n", "<space>li", toggle_inlay_hints, { silent = true, desc = "Toggle inlay hints" } },
        },
        ["textDocument/rangeFormatting"] = {
        },
        ["textDocument/references"] = {
            { "n", "grr", with_telescope and "<cmd>Telescope lsp_references<cr>"
            or vim.lsp.buf.references, { silent = true, desc = "Find references" } },
        },
        ["textDocument/rename"] = {
            { "n", "grn", vim.lsp.buf.rename, { silent = true, desc = "Rename symbol" } },
        },
        ["textDocument/typeDefinition*"] = {
            { "n", "grd", with_telescope and "<cmd>Telescope lsp_type_definitions<cr>"
            or vim.lsp.buf.type_definition, { silent = true, desc = "Go to type definition" } },
        },
        ["workspace/workspaceFolders"] = {
            { "n", "<leader>lw", "<nop>",                             { desc = "Workspace" } },
            { "n", "<space>lwa", vim.lsp.buf.add_workspace_folder,    { silent = true, desc = "Add folder" } },
            { "n", "<space>lwr", vim.lsp.buf.remove_workspace_folder, { silent = true, desc = "Remove folder" } },
            { "n", "<space>lwl", list_workspace_folders,              { silent = true, desc = "List folders" } },
        },
        ["no_requirements"] = {
            { "n", "<leader>l", "<nop>",                                             { desc = "Lsp" } },
            { "n", "gl",        vim.diagnostic.open_float,                           { silent = true, desc = "Open diagnostics" } },
            { "n", "<space>lk", function () vim.diagnostic.jump({ count = -1 }) end, { silent = true, desc = "Go to prev diagnostic" } },
            { "n", "<space>lj", function () vim.diagnostic.jump({ count = 1 }) end,  { silent = true, desc = "Go to next diagnostic" } },
        },
    },
}
