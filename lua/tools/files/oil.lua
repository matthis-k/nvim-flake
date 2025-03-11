local border = require("constants").wins.border
local M = {}
local MAX_WIDTH = 40
local ns = vim.api.nvim_create_namespace("FileExplorer")
local FileExplorer = {}
FileExplorer.__index = FileExplorer
setmetatable(FileExplorer, {
    __call = function (_, dir)
        dir = dir or vim.fn.getcwd()
        if not vim.fn.isdirectory(dir) then
            vim.notify(string.format("%s is not a directory", vim.inspect("str")), vim.log.levels.ERROR)
            return
        end
        ---@type FileExplorer
        local instance = setmetatable({
            dir = dir,
            title = dir,
            row = 0,
            col = 0,
            show_hidden = false,
            buf = vim.api.nvim_create_buf(false, true),
            prev_win_id = vim.api.nvim_get_current_win(),
            width = 1,
            height = 1,
            win = 0,
            entries = {},
            visible_entries = {},
            marked = {},
        }, FileExplorer)

        if instance.buf == 0 then
            vim.notify("Buffer creation failed: " .. tostring(instance.buf), vim.log.levels.ERROR)
            return nil
        end

        local win_config = {
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
        }
        instance.win = vim.api.nvim_open_win(instance.buf, true, win_config)
        if instance.win == 0 then
            vim.api.nvim_buf_delete(instance.buf, { force = true })
            vim.notify("Window creation failed: " .. tostring(win), vim.log.levels.ERROR)
            return nil
        end

        vim.wo[instance.win].sidescrolloff = 0
        vim.b[instance.buf].completion = false

        instance:render()

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

        map("n", "<cr>", function () instance:move_right() end, opts)
        map("n", "<bs>", function () instance:move_left() end, opts)
        map("n", "<esc>", function () instance:quit() end, opts)

        map("n", ".", function () vim.notify(unpack(instance:cd())) end, opts)
        map("n", "gh", function () vim.notify(unpack(instance:toggle_hidden())) end, opts)

        map("n", "d", function () vim.notify(unpack(instance:delete())) end, opts)
        map("n", "y", function ()
            instance.insert_action = FileExplorer.copy
            vim.api.nvim_win_set_height(instance.win, instance.height + 1)
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("o", true, false, true), "n", true)
        end, opts)
        local rename_keys = { "i", "I", "a", "A", "c", "C", "o" }
        for _, key in ipairs(rename_keys) do
            map("n", key, function ()
                instance.insert_action = (key == "o") and FileExplorer.create or FileExplorer.rename
                if key == "o" then vim.api.nvim_win_set_height(instance.win, instance.height + 1) end
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, false, true), "n", true)
            end, opts)
        end

        map("i", "<cr>", function ()
            if instance.insert_action then
                local msg = instance:insert_action()
                vim.cmd.stopinsert()
                vim.notify(unpack(msg))
                instance:render()
                instance.insert_action = nil
            end
        end, opts)

        map("i", "<esc>", function () instance:cancel_action() end, opts)


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

function FileExplorer:update_data()
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

    local max_line_len = 10
    for _, entry in ipairs(self.visible_entries) do
        local name, _ = unpack(entry)
        if self.show_hidden or not name:match("^%..*$") then
            max_line_len = math.max(max_line_len, vim.fn.strdisplaywidth(name))
        end
    end
    self.width = math.min(math.max(max_line_len, vim.fn.strdisplaywidth(self.title)), MAX_WIDTH)
    self.height = math.max(#self.visible_entries, 1)

    self.col = (vim.o.columns - self.width) / 2
end

function FileExplorer:toggle_hidden()
    self.show_hidden = self.show_hidden ~= true
    return notify(true, "Toggle hidden", (self.show_hidden and "enabled") or "disabled", nil)
end

function FileExplorer:cd()
    local ok, err = pcall(function ()
        vim.cmd.cd(self.dir)
    end)
    if ok then
        return notify(true, "Change working directory", self.dir, nil)
    else
        return notify(false, "Change working directory", self.dir, err)
    end
end

function FileExplorer:set_dir(dir)
    self.dir = dir
    self.title = dir
end

function FileExplorer:move_left()
    self:set_dir(vim.fn.fnamemodify(self.dir, ":h"))
    self:render()
end

function FileExplorer:show_data()
    local lines = {}
    for _, entry in ipairs(self.visible_entries) do
        local name, _ = unpack(entry)
        local line = name
        table.insert(lines, line)
    end
    vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, lines)

    vim.api.nvim_buf_clear_namespace(self.buf, ns, 0, -1)
    for i, entry in ipairs(self.visible_entries) do
        local entry_name = entry[1]
        local entry_display_width = vim.fn.strdisplaywidth(entry_name)
        local is_truncated = (entry_display_width > self.width)
        local indicator

        if is_truncated then
            indicator = "…"
        end

        if indicator then
            local virt_text = { { indicator, "Constant" } }
            vim.api.nvim_buf_set_extmark(self.buf, ns, i - 1, 0, {
                priority = 5,
                virt_text = virt_text,
                virt_text_pos = "right_align",
                hl_mode = "combine",
            })
        end

        if entry[2] == "directory" then
            vim.hl.range(self.buf, ns, "Directory", { i - 1, 0 }, { i - 1, -1 })
            vim.api.nvim_buf_set_extmark(self.buf, ns, i - 1, 0, {
                virt_text = { { "/", "Directory" } },
                virt_text_pos = "eol",
                hl_mode = "combine",
            })
        end
    end
end

function FileExplorer:move_right()
    local selected = self:get_selection()
    if selected.type == "directory" then
        self:set_dir(self.dir .. "/" .. selected.name)
        self:render()
    else
        self:open_file(selected)
        self:quit(true)
    end
end

function FileExplorer:get_selection(idx)
    local idx = idx or vim.api.nvim_win_get_cursor(self.win)[1]
    local selected = self.visible_entries[idx]
    if not selected then
        vim.notify("No entry selected", vim.log.levels.WARN)
        return {}
    end
    local name, type = unpack(selected)

    return {
        idx = idx,
        name = name,
        type = type,
    }
end

function FileExplorer:open_file(selected)
    selected = selected or self:get_selection()
    local ok, err = pcall(function ()
        vim.api.nvim_win_call(self.prev_win_id, function ()
            vim.cmd.edit(self.dir .. "/" .. selected.name)
        end)
    end)
    if not ok then
        vim.notify("Failed to open file: " .. tostring(err), vim.log.levels.ERROR)
    end
end

local function notify(success, action, path, err)
    if success then
        return { string.format("%s successful: %s", action, path), vim.log.levels.INFO }
    else
        return { string.format("%s failed: %s", action, err or path), vim.log.levels.ERROR }
    end
end

function FileExplorer:create()
    local line = vim.api.nvim_get_current_line()
    if line == "" then
        return notify(false, "File creation", nil, "No name provided")
    end

    local is_dir = line:sub(-1) == "/"
    local new_path = vim.fs.normalize(vim.fs.joinpath(self.dir, line))

    local parent = vim.fs.dirname(new_path)
    pcall(vim.fn.mkdir, parent, "p", 448)

    local res
    if is_dir then
        local ok, err = pcall(vim.fn.mkdir, new_path, "p", 448) -- 0o700
        res = notify(ok, "Directory creation", new_path, err)
    else
        local fd, err = vim.loop.fs_open(new_path, "w", 420) -- 0o644
        if not fd then
            res = notify(false, "File creation", new_path, err)
        else
            vim.loop.fs_close(fd)
            res = notify(true, "File creation", new_path)
        end
    end
    self:render()
    return res
end

function FileExplorer:delete()
    local sel = self:get_selection()
    if not sel or not sel.name then
        return notify(false, "File creation", nil, "No name provided")
    end
    local target_path = vim.fs.normalize(vim.fs.joinpath(self.dir, sel.name))
    local stat = vim.loop.fs_stat(target_path)
    local flags = (stat and stat.type == "directory") and "rf" or ""
    local ok, err = pcall(vim.fn.delete, target_path, flags)
    self:render()
    return notify(ok, "Deletion", target_path, err)
end

function FileExplorer:rename()
    local sel = self:get_selection()
    if not sel or not sel.name then
        return vim.notify("No selection", vim.log.levels.ERROR)
    end

    local orig_path = vim.fs.normalize(vim.fs.joinpath(self.dir, sel.name))
    local new_name = vim.api.nvim_get_current_line()
    if new_name == "" then
        return vim.notify("No new name provided", vim.log.levels.ERROR)
    end


    local new_path = vim.fs.normalize(vim.fs.joinpath(self.dir, new_name))

    local parent = vim.fs.dirname(new_path)
    pcall(vim.fn.mkdir, parent, "p", 448)

    local ok, err = vim.loop.fs_rename(orig_path, new_path)
    if ok then
        self:update_buffers(orig_path, new_path)
    end
    self:render()
    return notify(ok, "Rename", new_path, err)
end

function FileExplorer:copy()
    local sel = self:get_selection()
    if not sel or not sel.name then
        return notify(false, "Copy", nil, "No selection")
    end

    local orig_path = vim.fs.normalize(vim.fs.joinpath(self.dir, self:get_selection(sel.idx - 1).name))
    local new_name = vim.api.nvim_get_current_line()
    if new_name == "" then
        return notify(false, "Copy", nil, "No target name provided")
    end

    local new_path = vim.fs.normalize(vim.fs.joinpath(self.dir, new_name))
    local ok, err = vim.loop.fs_copyfile(orig_path, new_path)
    self:render()
    return notify(ok, "Copy", new_path, err)
end

function FileExplorer:update_buffers(old_path, new_path)
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_get_name(buf) == old_path then
            vim.api.nvim_buf_set_name(buf, new_path)
        end
    end
end

function FileExplorer:cancel_action()
    self.insert_action = nil
    vim.cmd.stopinsert()
    self:render()
end

function FileExplorer:quit()
    vim.api.nvim_win_close(self.win, true)
    vim.api.nvim_buf_delete(self.buf, { force = true })
end

function FileExplorer:render()
    self:update_data()
    self:show_data()

    if vim.api.nvim_win_is_valid(self.win) then
        local config = {
            relative = "tabline",
            anchor = "NW",
            width = self.width,
            height = self.height,
            row = self.row,
            col = self.col,
            focusable = true,
            style = "minimal",
            border = border,
            title = self.title,
            title_pos = "left",
        }
        local ok, err = pcall(vim.api.nvim_win_set_config, self.win, config)
        if not ok then
            vim.notify("Failed to update window config: " .. tostring(err), vim.log.levels.ERROR)
        end
        vim.api.nvim_win_call(self.win, function ()
            local view = vim.fn.winsaveview()
            view.topline = 1
            view.leftcol = 0
            vim.fn.winrestview(view)
        end)
    end
end

M.open = FileExplorer

return M
