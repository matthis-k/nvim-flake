local NuiTree = require("nui.tree")
local Line = require("nui.line")
local Text = require("nui.text")
local devicons = require("nvim-web-devicons")

local bufnr = vim.api.nvim_create_buf(false, true)
local win = vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    col = math.floor(vim.o.columns / 4),
    row = math.floor(vim.o.lines / 4),
    width = math.ceil(vim.o.columns / 2),
    height = math.ceil(vim.o.lines / 2),
})
vim.wo[win].statuscolumn = ""
vim.wo[win].relativenumber = false
vim.wo[win].number = false



local root_path = "/home/matthisk/nvim-flake/"

local M = {}

M.create_node = function (path, is_dir)
    path = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
    local basename = vim.fn.fnamemodify(path, ":t")

    return NuiTree.Node({
        path = path,
        basename = basename,
        is_dir = is_dir == true,
    }, M.get_children(path))
end

M.prepare_node = function (node)
    local basename = node.basename

    local icon = ""
    local hl_group = "Directory"

    if not node.is_dir then
        local _icon, _hl = devicons.get_icon(basename, vim.fn.fnamemodify(basename, ":e"), { default = true })
        if _icon then
            icon = _icon
            hl_group = _hl or "Normal"
        end
    end

    local line = Line()
    line:append(Text("", {
        virt_text = { { string.rep("  ", node:get_depth() - 1), nil } },
        virt_text_pos = "inline",
    }))

    line:append(Text("", {
        virt_text = { { icon, hl_group } },
        virt_text_pos = "inline",
    }))

    if node:has_children() then
        line:append(Text("", {
            virt_text = { { node:is_expanded() and " " or " ", nil } },
            virt_text_pos = "inline",
        }))
    else
        line:append(Text("", {
            virt_text = { { "  ", nil } },
            virt_text_pos = "inline",
        }))
    end

    line:append(" " .. basename)

    return line
end

M.get_children = function (path)
    local scanner = vim.uv.fs_scandir(path)
    local dirs, files = {}, {}
    if scanner then
        while true do
            local name, type = vim.uv.fs_scandir_next(scanner)
            if not name then
                break
            end
            local is_dir = type == "directory"
            table.insert(is_dir and dirs or files, M.create_node(path .. "/" .. name, is_dir))
        end
    end
    local children = {}
    vim.list_extend(children, dirs)
    vim.list_extend(children, files)
    return children
end

local tree = NuiTree({
    bufnr = bufnr,
    prepare_node = M.prepare_node,
    nodes = M.get_children(root_path),
})

tree:render()
local pos = vim.api.nvim_win_get_cursor(0)
if pos[2] == 0 then
    vim.api.nvim_win_set_cursor(0, { pos[1], 1 })
end

local function safe_motion(motion)
    return function ()
        vim.cmd("normal! " .. motion)
        local pos = vim.api.nvim_win_get_cursor(0)
        if pos[2] == 0 then
            vim.api.nvim_win_set_cursor(0, { pos[1], 1 })
        end
    end
end

local wrapped_motions = {
    n = {
        "h", "j", "k",
        "<Left>", "<Down>", "<Up>",
        "b", "ge",
        "$", "0",
    },
    i = {
    },
}
local disabled_motions = {
    n = {
        "<Up>", "<Down>", "<Left>", "<Right>",
    },
    i = {
        "<Up>", "<Down>",
    },
}

for mode, motions in pairs(wrapped_motions) do
    for _, motion in ipairs(motions) do
        vim.keymap.set(mode, motion, safe_motion(motion), { buffer = bufnr, silent = true })
    end
end

for mode, motions in pairs(disabled_motions) do
    for _, motion in ipairs(motions) do
        vim.keymap.set(mode, motion, "<nop>", { buffer = bufnr, silent = true })
    end
end

---@enum "rename" | "create" | nil
local action = nil

vim.keymap.set("n", "<cr>", function ()
    local node = tree:get_node()
    if not node then return end
    if node.is_dir then
        if node:is_expanded() then
            node:collapse()
        else
            node:expand()
        end
    else
        vim.cmd.edit(node.path)
    end
    tree:render()
end, { buffer = bufnr, noremap = true, silent = true })

vim.keymap.set("n", "i", function ()
    local node = tree:get_node()
    if not node then return end
    vim.bo[bufnr].readonly = false
    vim.bo[bufnr].modifiable = true
    vim.cmd.startinsert()
    action = "rename"
end, { buffer = bufnr, noremap = true, silent = true })

vim.keymap.set("i", "<cr>", function ()
    local node = tree:get_node()
    if not node then return end
    -- implement actions here
    vim.cmd.stopinsert()
    action = "nil"
end, { buffer = bufnr, noremap = true, silent = true })
