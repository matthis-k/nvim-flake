local NuiTree = require("nui.tree")
local Line = require("nui.line")
local Text = require("nui.text")
local devicons = require("nvim-web-devicons")


local OilTree = {}
OilTree.__index = OilTree
function OilTree.new(path)
    path = path or vim.fn.getcwd()
    local instance = {
        root = path,
    }
    return setmetatable(instance, OilTree)
end

function OilTree:open(path)
    self:set_root(path)

    if not self.buf then
        self.buf = vim.api.nvim_create_buf(false, true)
    end
    if not self.win then
        local width = math.max(math.ceil(vim.o.columns / 5), 40)

        self.win = vim.api.nvim_open_win(self.buf, true, {
            split = "right",
            width = width,
        })

        vim.wo[self.win].statuscolumn = ""
        vim.wo[self.win].relativenumber = false
        vim.wo[self.win].number = false
    end
    self:update_tree()

    self.tree:render()
    vim.keymap.set("n", "<CR>", function ()
        local node = self.tree:get_node()
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
        self.tree:render()
    end, { buffer = self.buf, noremap = true, silent = true })

    for _, key in ipairs({ "<c-v>", "V", "v", "i", "I", "a", "A", "c", "C", "s", "S", "R" }) do
        vim.keymap.set("n", key, function ()
            local node = self.tree:get_node()
            if not node then return end
            self.action = "rename"
            self:open_rename_window(node, key)
        end, { buffer = self.buf, noremap = true, silent = true })
    end
end

function OilTree:close()
    if self.rename_win and vim.api.nvim_win_is_valid(self.rename_win) then
        vim.api.nvim_win_close(self.rename_win, true)
    end
    if self.win and vim.api.nvim_win_is_valid(self.win) then
        vim.api.nvim_win_close(self.win, true)
    end
    if self.rename_buf and vim.api.nvim_buf_is_valid(self.rename_buf) then
        vim.api.nvim_buf_delete(self.rename_buf, { force = true })
    end
    if self.buf and vim.api.nvim_buf_is_valid(self.buf) then
        vim.api.nvim_buf_delete(self.buf, { force = true })
    end

    self.buf = nil
    self.rename_buf = nil
    self.rename_win = nil
    self.win = nil
    self.action = nil
    self.tree = nil
end

function OilTree:toggle(path)
    if self.win and vim.api.nvim_win_is_valid(self.win) then
        self:close()
    else
        self:open(path or self.root)
    end
end

function OilTree:cd(path)
    vim.fn.chdir(path)
    self:set_root(path)
    self:update_tree()
    self.tree:render()
end

function OilTree:set_root(path)
    self.root = path or vim.fn.getcwd()
end

function OilTree:update_tree()
    self.tree = NuiTree({
        bufnr = self.buf,
        prepare_node = OilTree.prepare_node,
        nodes = OilTree.get_children(self.root),
    })
end

OilTree.create_node = function (path, is_dir)
    path = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
    local basename = vim.fn.fnamemodify(path, ":t")

    return NuiTree.Node({
        path = path,
        basename = basename,
        is_dir = is_dir == true,
    }, OilTree.get_children(path))
end

OilTree.prepare_node = function (node)
    local basename = node.basename
    local icon = ""
    local hl_group = "Directory"

    if not node.is_dir then
        local _icon, _hl = devicons.get_icon(
            basename,
            vim.fn.fnamemodify(basename, ":e"),
            { default = true }
        )
        if _icon then
            icon = _icon
            hl_group = _hl or "Normal"
        end
    end

    local line = Line()

    line:append(Text(basename, {
        virt_text = {
            { string.rep("  ", node:get_depth() - 1), nil },
            { node:has_children() and (node:is_expanded() and " " or " ") or "  ", nil },
            { icon .. " ", hl_group } },
        virt_text_pos = "inline",
    }))
    return line
end

OilTree.get_children = function (path)
    local scanner = vim.uv.fs_scandir(path)
    local dirs, files = {}, {}
    if scanner then
        while true do
            local name, t = vim.uv.fs_scandir_next(scanner)
            if not name then break end
            local is_dir = t == "directory"
            table.insert(is_dir and dirs or files,
                OilTree.create_node(path .. "/" .. name, is_dir))
        end
    end
    local children = {}
    vim.list_extend(children, dirs)
    vim.list_extend(children, files)
    return children
end

function OilTree:open_rename_window(node, trigger_key)
    if self.rename_win and vim.api.nvim_win_is_valid(self.rename_win) then
        vim.api.nvim_win_close(self.rename_win, true)
    end

    self.rename_buf = vim.api.nvim_create_buf(false, true)
    local cur_row = vim.api.nvim_win_get_cursor(self.win)[1] - 1

    local indent_cols = (node:get_depth() - 1) * 2
    local start_col = indent_cols + 7
    local tree_width = vim.api.nvim_win_get_width(self.win)
    local text_width = math.max(1, tree_width - start_col)

    self.rename_win = vim.api.nvim_open_win(self.rename_buf, true, {
        relative = "win",
        win = self.win,
        anchor = "NW",
        row = cur_row,
        col = start_col,
        width = text_width,
        height = 1,
        focusable = true,
        style = "minimal",
        border = "none",
    })

    vim.api.nvim_buf_set_lines(self.rename_buf, 0, -1, false, { node.basename })
    vim.bo[self.rename_buf].modifiable = true
    vim.bo[self.rename_buf].buftype = ""

    vim.api.nvim_win_set_cursor(self.rename_win, { 1, vim.api.nvim_win_get_cursor(self.win)[2] })
    local key = vim.api.nvim_replace_termcodes(trigger_key, true, false, true)
    vim.api.nvim_feedkeys(key, "n", false)

    -- <CR> in insert or normal mode finalizes rename (if valid)
    local function commit_rename()
        if self.action ~= "rename" then return end
        vim.cmd.stopinsert()

        if self.rename_win and vim.api.nvim_win_is_valid(self.rename_win) then
            local lines = vim.api.nvim_buf_get_lines(self.rename_buf, 0, -1, false)
            if #lines > 1 then
                vim.notify("Multiline rename not supported", vim.log.levels.ERROR)
            else
                vim.print("rename: " .. lines[1])
            end
            vim.api.nvim_win_close(self.rename_win, true)
        end
        self.action = nil
    end

    vim.keymap.set("i", "<CR>", commit_rename, { buffer = self.rename_buf, noremap = true, silent = true })
    vim.keymap.set("n", "<CR>", commit_rename, { buffer = self.rename_buf, noremap = true, silent = true })

    vim.keymap.set("n", "<Esc>", function ()
        if self.rename_win and vim.api.nvim_win_is_valid(self.rename_win) then
            vim.api.nvim_win_close(self.rename_win, true)
        end
        self.action = nil
    end, { buffer = self.rename_buf, noremap = true, silent = true })
end

local fe = OilTree:new()
fe:open()

return OilTree
