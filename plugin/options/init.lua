local tabwidth = 4

vim.loader.enable("true")

vim.g.mapleader = require("keymaps").leader
vim.g.maplocalleader = require("keymaps").leader

local opt = vim.opt

opt.swapfile = false
opt.breakindent = true
opt.timeoutlen = 100
opt.autowrite = true
opt.autoread = true
opt.clipboard = "unnamedplus"
opt.completeopt = "menu,menuone,noselect,preview"
opt.conceallevel = 3
opt.confirm = true
opt.cursorline = true
opt.expandtab = true
opt.formatoptions = "jcroqlnt"
opt.grepformat = "%f:%l:%c:%m"
opt.grepprg = "rg --vimgrep"
opt.ignorecase = true
opt.inccommand = "nosplit"
opt.list = false

opt.mouse = "a"
opt.number = true
opt.relativenumber = true
opt.pumblend = 0
opt.winblend = 0
opt.pumheight = 10
opt.scrolloff = 4
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize" }
opt.shiftround = true
opt.shiftwidth = tabwidth
opt.shortmess:append({ W = true, I = true, c = true, m = true })
opt.showmode = false
opt.sidescrolloff = 8
opt.signcolumn = "yes"
opt.smartcase = true
opt.smartindent = true
opt.spelllang = { "en" }
opt.splitbelow = true
opt.splitright = true
opt.tabstop = tabwidth
opt.termguicolors = true
opt.timeoutlen = 300
opt.undofile = true
opt.undolevels = 10000
opt.updatetime = 200
opt.wildmode = "longest:full,full"
opt.winminwidth = 5
opt.wrap = false
opt.foldmethod = "expr"
opt.foldexpr = "nvim_treesitter#foldexpr()"
opt.foldcolumn = "1"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true

vim.o.winborder = table.concat(require("constants").wins.border, ",")

if vim.fn.has("nvim-0.9.0") == 1 then
    opt.splitkeep = "screen"
    opt.shortmess:append({ C = true })
end

vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
    desc = "Highlights yanked text",
    callback = function ()
        vim.highlight.on_yank({ higroup = "Visual" })
    end,
})

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("LspFolds", { clear = true }),
    desc = "Enables LSP driven folds if supported",
    callback = function (ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if not client then
            return
        end
        if client:supports_method("textDocument/foldingRange") then
            vim.api.nvim_set_option_value("foldexpr", "v:lua.vim.lsp.foldexpr()", {})
        end
    end,
})

vim.g.markdown_recommended_style = 0
