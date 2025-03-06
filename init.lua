vim.g.lz_n = {
    load = vim.cmd.packadd,
}

require("options")

require("keymaps")

require("theme")

require("session")

require("lsp")

require("completion")

require("git")

require("ui")
