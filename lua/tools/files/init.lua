local border = require("constants").wins.border
local M = {}
local MAX_WIDTH = 40
local ns = vim.api.nvim_create_namespace("FileExplorer")
local utf8len = function (str)
    return #vim.str_utf_pos(str)
end

---@class Entry
---@field [1] string name of entry
---@field [2] "directory"|"file"|"link"|"fifo"|"socket"|"char"|"block"|"unknown" type of entry


---@class FileExplorer
---@field prev_win_id number
---@field win number
---@field buf number
---@field width number
---@field height number
---@field row number
---@field col number
---@field entries Entry[]
---@field visible_entries Entry[]
---@field show_hidden boolean
---@field dir string
---@field title string
---@field marked table<string, boolean>
---@field insert_action? "rename"|"create"|"copy"
---@field parent? FileExplorer
---@field child? FileExplorer
local FileExplorer = {}
FileExplorer.__index = FileExplorer
setmetatable(FileExplorer, {
    __call = function (_, dir, parent)
        dir = dir or vim.fn.getcwd()
        if not vim.fn.isdirectory(dir) then
            vim.notify(string.format("%s is not a directory", vim.inspect("str")), vim.log.levels.ERROR)
        end
        ---@type FileExplorer
        local instance = setmetatable({
            dir = dir,
            parent = parent,
            title = parent and dir:sub(#parent.dir + 1) or dir,
            row = parent and parent.row or 0,
            col = parent and parent.col + parent.width + 2 or 0,
            show_hidden = false,
            buf = vim.api.nvim_create_buf(false, true),
            prev_win_id = parent and parent.prev_win_id or vim.api.nvim_get_current_win(),
            width = 1,
            height = 1,
            win = 0,
            entries = {},
            visible_entries = {},
            marked = {},
        }, FileExplorer)


        instance:update_entries()
        instance:set_buf_content()
        instance.win = vim.api.nvim_open_win(instance.buf, true, {
            relative = "tabline",
            anchor = "NW",
            width = instance.width,
            height = instance.height,
            row = instance.row,
            col = instance.col,
            focusable = true,
            style = "minimal",
            border = border,
            title = instance.title,
            title_pos = "left",
        })
        vim.wo[instance.win].sidescrolloff = 0

        instance:disable_keys({
            i = {
                "<Up>", "<Down>", "<C-y>", "<C-e>", "<PageUp>", "<PageDown>",
                "<C-o>j", "<C-o>k", "<C-o><Up>", "<C-o><Down>",
            },
            v = { "j", "k", "<Up>", "<Down>", "gj", "gk" },
            n = { "/", "?", "v", "V", "<C-v>", "q", "q:", "g:", "x" },
        })


        local map = vim.keymap.set
        local opts = { buffer = instance.buf }

        local rename_keys = { "i", "I", "a", "A", "c", "C", "o" }
        for _, key in ipairs(rename_keys) do
            map("n", key, function ()
                instance.insert_action = (key == "o") and "create" or "rename"
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, false, true), "n", true)
            end, opts)
        end

        map("n", "<cr>", function () instance:enter_child() end, opts)
        map("n", "<s-cr>", function () instance:enter_child(true) end, opts)

        map("n", "h", function () instance:enter_parent() end, opts)
        map("n", "l", function () instance:enter_child() end, opts)
        map("n", ".", function () instance:set_dir() end, opts)
        map("n", "gh", function () instance:toggle_hidden() end, opts)

        map("n", "H", "h", opts)
        map("n", "J", "j", opts)
        map("n", "K", "k", opts)
        map("n", "L", "l", opts)

        map("n", "S", function () instance:mark({ reset = true }) end, opts)
        map("n", "s", function () instance:mark() end, opts)
        map("n", "m", function () instance:move() end, opts)

        map("n", "q", function () instance:quit() end, opts)
        map("n", "<esc>", function () instance:quit(true) end, opts)
        map("i", "<cr>", function ()
            if instance.insert_action == "rename" then
                instance:rename_file()
            elseif instance.insert_action == "create" then
                instance:create_file()
            elseif instance.insert_action == "copy" then
                instance:copy_single()
            end
            instance.insert_action = nil
        end, opts)
        map("i", "<esc>", function () instance:cancel_action() end, opts)

        map("n", "d", function () instance:delete_file() end, opts)
        map("n", "D", function () instance:delete_file({ marked = true }) end, opts)

        map("n", "P", function () instance:copy_marked() end, opts)
        map("n", "p", function ()
            instance.insert_action = "copy"
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("o", true, false, true), "n", true)
        end, opts)
        return instance
    end,
})

function FileExplorer:disable_keys(mappings)
    for modes, keys in pairs(mappings) do
        for _, key in ipairs(keys) do
            vim.keymap.set(vim.split(modes, ""), key, "<nop>", { buffer = self.buf })
        end
    end
end

function FileExplorer:update_entries()
    self.entries = vim.iter(vim.fs.dir(self.dir, {})):totable()
    table.sort(self.entries, function (a, b)
        local nameA, typeA = a[1], a[2]
        local nameB, typeB = b[1], b[2]
        local isDirA, isDirB = typeA == "directory", typeB == "directory"
        if isDirA ~= isDirB then
            return isDirA
        else
            local lowerA, lowerB = nameA:lower(), nameB:lower()
            if lowerA == lowerB then
                return nameA < nameB
            else
                return lowerA < lowerB
            end
        end
    end)
    self.visible_entries = vim.iter(self.entries):filter(function (entry)
        return self.show_hidden or not entry[1]:match("^%..*$")
    end):totable()

    self:update_size()
end

function FileExplorer:toggle_hidden()
    self.show_hidden = self.show_hidden ~= true
    self:rerender()
end

function FileExplorer:set_dir(dir)
    if not dir then
        local selection = self:get_selection()
        dir = self.dir .. "/" .. selection.name
        vim.cmd.cd(dir)
    end
    self.dir = dir
    self.title = self.parent and dir:sub(#self.parent.dir + 1) or dir
    self:rerender()
end

function FileExplorer:enter_parent()
    if self.parent then
        vim.api.nvim_set_current_win(self.parent.win)
    else
        self:set_dir(vim.fn.fnamemodify(self.dir, ":h"))
    end
end

function FileExplorer:set_buf_content()
    local lines = {}
    for i, entry in ipairs(self.visible_entries) do
        local name, _ = unpack(entry)
        local line = name
        table.insert(lines, line)
    end
    vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)
    for i, entry in ipairs(self.visible_entries) do
        local entry_name = entry[1]
        local entry_display_width = vim.fn.strdisplaywidth(entry_name)
        local is_marked = self.marked[vim.fn.fnameescape(self.dir .. "/" .. entry_name)]
        local is_truncated = (entry_display_width > self.width)
        local indicator

        if is_truncated and is_marked then
            indicator = "… [x]"
        elseif is_truncated then
            indicator = "…"
        elseif is_marked then
            indicator = "[x]"
        end

        if indicator then
            local virt_text = { { indicator, "Constant" } }
            local indicator_width = vim.fn.strdisplaywidth(indicator)
            local win_col = math.max(0, self.width - indicator_width)
            vim.api.nvim_buf_set_extmark(self.buf, ns, i - 1, 0, {
                priority = 5,
                virt_text = virt_text,
                virt_text_pos = "overlay",
                virt_text_win_col = win_col,
                hl_mode = "combine",
            })
        end

        if entry[2] == "directory" then
            vim.hl.range(self.buf, ns, "Directory", { i - 1, 0 }, { i - 1, -1 })
            local dir_mark_col = math.min(entry_display_width, self.width - 1)
            vim.api.nvim_buf_set_extmark(self.buf, ns, i - 1, 0, {
                priority = 4,
                virt_text = { { "/", "Directory" } },
                virt_text_pos = "overlay",
                virt_text_win_col = dir_mark_col,
                hl_mode = "combine",
            })
        end
    end
end

function FileExplorer:update_size()
    local max_line_len = 10
    for _, entry in ipairs(self.visible_entries) do
        local name, _ = unpack(entry)
        if self.show_hidden or not name:match("^%..*$") then
            max_line_len = math.max(max_line_len, utf8len(name))
        end
    end
    self.width = math.min(math.max(max_line_len + 4, utf8len(self.title)), MAX_WIDTH)
    self.height = math.max(#self.visible_entries, 1)
end

function FileExplorer:enter_child(stay_open)
    local selected = self:get_selection()
    if selected.type == "directory" then
        if self.child then
            self.child:quit()
        end
        self.child = FileExplorer(selected.path, self)
        return self.child
    else
        self:open_file(selected)
        if not stay_open then
            self:quit(true)
        end
    end
end

function FileExplorer:open_file(selected)
    selected = selected or self:get_selection()
    vim.api.nvim_set_current_win(self.prev_win_id)
    vim.cmd.edit(selected.path)
    vim.api.nvim_set_current_win(self.win)
end

function FileExplorer:delete_file(opts)
    opts = vim.tbl_deep_extend("keep", opts or {}, { marked = false })
    local files_to_delete = {}

    if opts.marked then
        files_to_delete = self:get_marks()
        if #files_to_delete == 0 then
            vim.notify("No marked files to delete", vim.log.levels.WARN)
            return
        end
    else
        local selected = self:get_selection()
        if not selected or not selected.name then
            vim.notify("No entry selected", vim.log.levels.WARN)
            return
        end
        files_to_delete = { selected.path }
    end

    for _, path in ipairs(files_to_delete) do
        local base_name = vim.fn.fnamemodify(path, ":t")
        local ok, err = pcall(function ()
            vim.fn.delete(path, "rf")
        end)
        if not ok then
            vim.notify("Error deleting " .. base_name .. ": " .. err, vim.log.levels.ERROR)
        else
            vim.notify(base_name .. " has been deleted", vim.log.levels.INFO)
        end
    end

    self.marked = {}
    self:rerender({ recursive = true })
end

function FileExplorer:get_selection(idx)
    local idx = idx or vim.api.nvim_win_get_cursor(self.win)[1]
    local selected = self.visible_entries[idx]
    if not selected then
        vim.notify("No entry selected", vim.log.levels.WARN)
        return {}
    end

    local name, type = unpack(selected)
    local path = vim.fn.fnameescape(self.dir .. "/" .. name)
    return {
        idx = idx,
        name = name,
        type = type,
        path = path,
    }
end

function FileExplorer:rename_file()
    local selection = self:get_selection()
    local new_name = vim.api.nvim_buf_get_lines(self.buf, selection.idx - 1, selection.idx, false)[1]
    new_name = vim.fn.fnamemodify(new_name, ":t")
    local old_path = selection.path
    local new_path = vim.fn.fnameescape(self.dir .. "/" .. new_name)
    local ok, err = os.rename(old_path, new_path)
    if not ok then
        vim.notify("Error renaming " .. selection.name .. ": " .. err, vim.log.levels.ERROR)
        return
    end
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
            local buf_name = vim.api.nvim_buf_get_name(buf)
            if buf_name == old_path then
                vim.api.nvim_buf_set_name(buf, new_path)
            end
        end
    end
    vim.cmd.stopinsert()
    self:rerender({ recursive = false })
end

function FileExplorer:create_file()
    local line = vim.api.nvim_get_current_line()
    local is_dir = line:sub(-1) == "/"
    local new_file
    if is_dir then
        -- Remove the trailing slash before getting the tail
        local trimmed = line:sub(1, -2)
        new_file = vim.fn.fnamemodify(trimmed, ":t")
    else
        new_file = vim.fn.fnamemodify(line, ":t")
    end
    local new_path = self.dir .. "/" .. new_file
    if is_dir then
        local ok, err = pcall(vim.fn.mkdir, new_path, "p")
        if ok then
            vim.notify(new_path .. " directory has been created", vim.log.levels.INFO)
        else
            vim.notify("Error creating directory " .. new_file .. ": " .. err, vim.log.levels.ERROR)
        end
    else
        new_path = vim.fn.fnameescape(new_path)
        local file = io.open(new_path, "w")
        if file then
            file:close()
            vim.notify(new_file .. " has been created", vim.log.levels.INFO)
        else
            vim.notify("Error creating file " .. new_file, vim.log.levels.ERROR)
        end
    end

    vim.cmd.stopinsert()
    self:rerender({ recursive = false })
end

function FileExplorer:copy_single()
    local selection = self:get_selection()
    local orig_path = self:get_selection(selection.idx - 1).path
    local new_path = vim.api.nvim_get_current_line()
    vim.uv.fs_copyfile(orig_path, new_path)
    vim.cmd.stopinsert()
    self:rerender({ recursive = false })
end

function FileExplorer:cancel_action()
    self.insert_action = nil
    vim.cmd.stopinsert()
    self:update_entries()
    self:set_buf_content()
end

function FileExplorer:mark(opts)
    opts = vim.tbl_deep_extend("keep", opts or {}, { toggle = true })
    if opts.reset then
        self.marked = {}
        self:set_buf_content()
        return
    end

    local selection = self:get_selection()
    if opts.toggle then
        self.marked[selection.path] = self.marked[selection.path] ~= true
    elseif opts.set_to then
        self.marked[selection.path] = opts.set_to
    end
    self:set_buf_content()
end

function FileExplorer:get_marks(opts)
    opts = vim.tbl_deep_extend("keep", opts or {}, { recursive = true })
    local result = {}
    if opts.recursive then
        local root = self
        while root.parent do
            root = root.parent
        end
        while root do
            vim.list_extend(result, vim.tbl_keys(root.marked))
        end
    else
        vim.list_extend(result, vim.tbl_keys(self.marked))
    end

    return result
end

function FileExplorer:move()
    local paths = self:get_marks()
    if #paths == 0 then
        vim.notify("No marked files to move", vim.log.levels.WARN)
        return
    end

    for _, old_path in ipairs(paths) do
        local base_name = vim.fn.fnamemodify(old_path, ":t")
        local new_path = vim.fn.fnameescape(self.dir .. "/" .. base_name)
        local ok, err = os.rename(old_path, new_path)
        if not ok then
            vim.notify("Error moving " .. old_path .. ": " .. err, vim.log.levels.ERROR)
        else
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_loaded(buf) then
                    local buf_name = vim.api.nvim_buf_get_name(buf)
                    if buf_name == old_path then
                        vim.api.nvim_buf_set_name(buf, new_path)
                    end
                end
            end
        end
    end

    self.marked = {}
    self:rerender({ recursive = true })
end

function FileExplorer:quit(quit_all)
    if self.child then
        self.child:quit()
    end
    vim.api.nvim_win_close(self.win, true)
    vim.api.nvim_buf_delete(self.buf, { force = true })
    vim.api.nvim_set_current_win(not quit_all and (self.parent and self.parent.win) or self.prev_win_id)
    if self.parent then
        self.parent.child = nil
        if quit_all then
            self.parent:quit(quit_all)
        end
    end
end

function FileExplorer:copy_marked()
    local paths = self:get_marks()
    if #paths == 0 then
        vim.notify("No marked files to copy", vim.log.levels.WARN)
        return
    end

    for _, old_path in ipairs(paths) do
        local base_name = vim.fn.fnamemodify(old_path, ":t")
        local new_path = vim.fn.fnameescape(self.dir .. "/" .. base_name)
        local copy_command

        -- Check if the path is a directory.
        if vim.fn.isdirectory(old_path) == 1 then
            copy_command = string.format("cp -r %s %s", vim.fn.fnameescape(old_path), new_path)
        else
            copy_command = string.format("cp %s %s", vim.fn.fnameescape(old_path), new_path)
        end

        local result = vim.fn.system(copy_command)
        if vim.v.shell_error ~= 0 then
            vim.notify("Error copying " .. base_name .. ": " .. result, vim.log.levels.ERROR)
        else
            vim.notify(base_name .. " has been copied", vim.log.levels.INFO)
        end
    end

    self.marked = {}
    self:rerender({ recursive = true })
end

function FileExplorer:rerender()
    opts = opts or {}
    local root = self
    while root.parent do
        root = root.parent
    end
    while root do
        if root.parent then
            root.row = root.parent.row
            root.col = root.parent.col + root.parent.width + 2
        end

        root:update_entries()
        root:set_buf_content()

        if vim.api.nvim_win_is_valid(root.win) then
            vim.api.nvim_win_set_config(root.win, {
                relative = "tabline",
                anchor = "NW",
                width = root.width,
                height = root.height,
                row = root.row,
                col = root.col,
                focusable = true,
                style = "minimal",
                border = border,
                title = root.title,
                title_pos = "left",
            })
        end

        vim.api.nvim_win_call(root.win, function ()
            local view = vim.fn.winsaveview()
            view.topline = 1
            view.leftcol = 0
            vim.fn.winrestview(view)
        end)

        root = root.child
    end
end

M.open = FileExplorer
return M
