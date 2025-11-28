local constants = require("constants")
local border = constants.wins.border


local dashboard_header = [[
                       _
 _ __   ___  _____   _(_)_ __ ___
| '_ \ / _ \/ _ \ \ / / | '_ ` _ \
| | | |  __/ (_) \ V /| | | | | | |
|_| |_|\___|\___/ \_/ |_|_| |_| |_|

]]

local function configure_snacks(Snacks)
    -- local function patch_picker_layout(node)
    --     if type(node) ~= "table" then
    --         return
    --     end
    --     if not node.layout and node.border == true then
    --         node.border = border
    --     end
    --     if node.layout then
    --         patch_picker_layout(node.layout)
    --     end
    --     for _, child in ipairs(node) do
    --         patch_picker_layout(child)
    --     end
    -- end
    -- for name, layout in pairs(require("snacks.picker.config.layouts")) do
    --     patch_picker_layout(layout)
    -- end

    local function dashboard_pick(cmd, opts)
        return function ()
            Snacks.dashboard.pick(cmd, opts)
        end
    end

    local function restore_last_session()
        local resession = require("resession")
        resession.load(vim.fn.getcwd(), { silence_errors = true })
    end

    local dashboard_keys = {
        { icon = " ", key = "f", desc = "Find file", action = dashboard_pick("files") },
        { icon = " ", key = "n", desc = "New file", action = ":ene | startinsert" },
        { icon = " ", key = "g", desc = "Live grep", action = dashboard_pick("live_grep") },
        { icon = " ", key = "r", desc = "Recent files", action = dashboard_pick("oldfiles") },
        { icon = " ", key = "e", desc = "File explorer", action = function () Snacks.explorer() end },
        {
            icon = " ",
            key = "c",
            desc = "Config files",
            action = dashboard_pick("files", { cwd = vim.fn.stdpath("config") }),
        },
        { icon = " ", key = "s", desc = "Restore session", action = restore_last_session },
        { icon = " ", key = "q", desc = "Quit Neovim", action = ":qa" },
    }

    Snacks.setup({
        explorer = {
            enabled = true,
            replace_netrw = true,
            trash = true,
        },
        gh = { enabled = true },
        dashboard = {
            enabled = true,
            width = 68,
            preset = {
                header = dashboard_header,
                keys = dashboard_keys,
            },
            sections = {
                { section = "header" },
                { section = "keys",  gap = 1, padding = 1 },
                {
                    icon = " ",
                    title = "Recent Files",
                    section = "recent_files",
                    indent = 2,
                    padding = 1,
                    limit = 5,
                },
                {
                    icon = " ",
                    title = "Projects",
                    section = "projects",
                    indent = 2,
                    padding = 1,
                    limit = 5,
                },
            },
            formats = {
                header = { "%s", align = "center", hl = "SnacksDashboardHeader" },
                icon = { "%s", width = 2, hl = "SnacksDashboardIcon" },
                desc = { "%s", hl = "SnacksDashboardDesc" },
                key = { "[%s]", hl = "SnacksDashboardKey" },
                title = { "%s", hl = "SnacksDashboardTitle" },
                footer = { "%s", align = "center", hl = "SnacksDashboardFooter" },
            },
        },
        indent = {
            enabled = true,
            indent = {
                char = "▏",
                only_current = false,
            },
            scope = {
                char = "▏",
                underline = false,
            },
            animate = { enabled = false },
        },
        input = {
            enabled = true,
            win = {
                style = "input",
                border = border,
                relative = "cursor",
                row = -3,
                col = 0,
                width = 60,
            },

            prompt_pos = "title",
        },
        notifier = {
            enabled = true,
            timeout = 4000,
            style = "compact",
            top_down = false,
            margin = { top = 0, right = 1, bottom = 0 },
        },
        picker = {
            enabled = true,
            prompt = " ",
            icons = {
                ui = {
                    selected = " ",
                    unselected = "  ",
                },
            },
            ui_select = true,
            layout = {
                cycle = true,
                preset = function ()
                    return vim.o.columns >= 120 and "default" or "vertical"
                end,
            },
            win = {
                input = {
                    border = border,
                    keys = {
                        ["<Esc>"] = { "close", mode = { "n", "i" } },
                    },
                },
                list = { border = border },
                preview = { border = border },
            },
            sources = {
                explorer = {
                    layout = { preset = "sidebar", preview = false },
                },
            },
        },
        rename = { enabled = true },
        terminal = {
            enabled = true,
            shell = vim.o.shell,
            win = function ()
                local config = {
                    border = border,

                    title = " Terminal ",
                    title_pos = "center",
                    width = 1,
                    height = 1,
                }
                if vim.o.columns >= vim.o.lines then
                    config.position = "right"
                    config.width = 0.35
                else
                    config.position = "bottom"
                    config.height = 0.35
                end
                return config
            end,
        },

        keymap = { enabled = true },
        styles = {
            notification = {
                border = border,
                wo = {
                    winhighlight = "NormalFloat:SnacksNotifier,FloatBorder:FloatBorder",
                },
            },
        },
    })
end

local ok, Snacks = pcall(require, "snacks")
if ok then
    configure_snacks(Snacks)
    return
end

require("lz.n").load({
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    after = function ()
        configure_snacks(require("snacks"))
    end,
})
