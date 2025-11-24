if not nixCats("opencode") then
    return
end

local constants = require("constants")

vim.o.autoread = true

vim.g.opencode_opts = vim.tbl_deep_extend("force", {
    ask = {
        prompt = "Ask opencode: ",
        snacks = {
            win = {
                border = constants.wins.border,
                title = "opencode",
                title_pos = "left",
                relative = "cursor",
                row = -3,
                col = 0,
            },
        },
    },
    select = {
        prompt = "opencode: ",
        snacks = {
            layout = { preset = "vscode" },
            win = {
                border = constants.wins.border,
            },
        },
    },
    provider = {
        enabled = "snacks",
        snacks = {
            auto_close = true,
            win = {
                position = "right",
                enter = false,
                border = constants.wins.border,
                wo = { winbar = "" },
                bo = { filetype = "opencode_terminal" },
            },
        },
    },
}, vim.g.opencode_opts or {})

require("lz.n").load({
    "opencode.nvim",
    keys = {
        {
            "<leader>oa",
            function ()
                require("opencode").ask("@this: ", { submit = true })
            end,
            mode = { "n", "x" },
            desc = "Ask opencode",
        },
        {
            "<leader>os",
            function ()
                require("opencode").select()
            end,
            mode = { "n", "x" },
            desc = "Execute opencode action…",
        },
        {
            "<leader>op",
            function ()
                require("opencode").prompt("@this")
            end,
            mode = { "n", "x" },
            desc = "Add to opencode",
        },
        {
            "<leader>oo",
            function ()
                require("opencode").toggle()
            end,
            mode = { "n" },
            desc = "Toggle opencode",
        },
        {
            "<leader>ok",
            function ()
                require("opencode").command("session.half.page.up")
            end,
            mode = "n",
            desc = "opencode half page up",
        },
        {
            "<leader>oj",
            function ()
                require("opencode").command("session.half.page.down")
            end,
            mode = "n",
            desc = "opencode half page down",
        },
    },
})
