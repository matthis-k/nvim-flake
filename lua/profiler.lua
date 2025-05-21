local NuiTree = require("nui.tree")
local Line = require("nui.line")
local Text = require("nui.text")

---@class ProfilerRun
---@field start integer
---@field stop integer
---@field duration integer

---@class ProfilerNode
---@field name string
---@field parent ProfilerNode|nil
---@field children table<string, ProfilerNode>
---@field current_start integer|nil
---@field total_duration integer
---@field total_count integer
---@field max_duration integer
---@field min_duration integer
---@field is_root boolean
local ProfilerNode = {}
ProfilerNode.__index = ProfilerNode

---@param name string
---@param parent ProfilerNode|nil
---@return ProfilerNode
function ProfilerNode.new(name, parent)
    return setmetatable({
        name = name,
        parent = parent,
        children = {},
        current_start = nil,
        total_duration = 0,
        total_count = 0,
        max_duration = 0,
        min_duration = -1,
        is_root = (not parent) or not parent.parent,
    }, ProfilerNode)
end

function ProfilerNode:start()
    if not self.current_start then
        self.current_start = vim.uv.hrtime() * (1e-6)
    end
end

function ProfilerNode:stop()
    if not self.current_start then return end
    local stop = vim.uv.hrtime() * (1e-6)
    local duration = stop - self.current_start
    self.total_duration = self.total_duration + duration
    self.total_count = self.total_count + 1
    self.max_duration = math.max(self.max_duration, duration)
    self.min_duration = self.min_duration > 0 and math.min(self.min_duration, duration) or duration
    self.current_start = nil
    local parent = self.parent
    if parent and not parent.current_start then
        parent.total_duration = parent.total_duration + duration
        parent.total_count = math.max(parent.total_count, self.total_count)
    end
end

---@param name string
---@return ProfilerNode
function ProfilerNode:get_child(name)
    if not self.children[name] then
        self.children[name] = ProfilerNode.new(name, self)
    end
    return self.children[name]
end

function ProfilerNode:get_root()
    if self.parent and not self.is_root then
        return self.parent:get_root()
    else
        return self
    end
end

---@return { name: string, count: integer, avg: number, max: number, min: number, percentage_rel: number, percentage_total: number }
function ProfilerNode:summary()
    return {
        name = self.name,
        percentage_rel = (self.is_root or not self.parent) and 1 or self.total_duration / self.parent.total_duration,
        percentage_total = self.total_duration / self:get_root().total_duration,
        total_duration = self.total_duration,
        count = self.total_count,
        avg = self.total_count > 0 and self.total_duration / self.total_count or 0,
        max = self.max_duration,
        min = self.min_duration,
    }
end

---@class Profiler
---@field enabled boolean
---@field stack ProfilerNode[]
---@field root ProfilerNode
local Profiler = {}
Profiler.__index = Profiler

---@return Profiler
function Profiler.new()
    return setmetatable({
        root = ProfilerNode.new("root"),
        stack = {},
        enabled = false,
    }, Profiler)
end

function Profiler:clean()
    self.root = ProfilerNode.new("root")
    self.stack = {}
end

function Profiler:toggle()
    self.enabled = self.enabled ~= true
end

---Start timing a named block or path
---@param name_or_path string|string[]
function Profiler:start(name_or_path)
    if not self.enabled then return end
    local node
    if type(name_or_path) == "table" then
        node = self.root
        for _, name in ipairs(name_or_path) do
            node = node:get_child(name)
        end
    else
        local parent = #self.stack > 0 and self.stack[#self.stack] or self.root
        node = parent:get_child(name_or_path)
    end
    node:start()
    table.insert(self.stack, node)
end

---@param name_or_path? string|string[]
function Profiler:stop(name_or_path)
    if not self.enabled then return end
    if type(name_or_path) == "table" then
        local node = self.root
        for _, name in ipairs(name_or_path) do
            node = node.children[name]
            if not node then return end
        end
        node:stop()
        for i = #self.stack, 1, -1 do
            if self.stack[i] == node then
                table.remove(self.stack, i)
                break
            end
        end
    elseif type(name_or_path) == "string" then
        for i = #self.stack, 1, -1 do
            if self.stack[i].name == name_or_path then
                self.stack[i]:stop()
                table.remove(self.stack, i)
                return
            end
        end
    else
        local node = table.remove(self.stack)
        if node then node:stop() end
    end
end

---@param _ string
---@param node ProfilerNode
---@return NuiTree.Node
local function build_tree(_, node)
    local data = node:summary()

    local children = vim.iter(node.children):map(build_tree):totable()

    if not node.parent then
        local header = NuiTree.Node({
            is_header = true,
            name = "Name",
            count = "Count",
            avg = "Avg",
            total = "Total",
            pct = "Percent",
            raw = node,
            baseline = true,
        })
        table.insert(children, 1, header)
    end

    return NuiTree.Node(data, children)
end

local Layout = {}

---@param win_width integer
---@param depth integer
---@return table
function Layout.compute(win_width, depth)
    local left_padding = 2
    local right_padding = 2
    local assignable_space = win_width - left_padding - right_padding
    local space_left = assignable_space

    local function assign(space, force)
        force = force ~= false
        if not force and space_left <= 0 then
            return 0
        else
            local assigned = math.min(space_left, space)
            space_left = space_left - assigned
            return assigned
        end
    end

    local W_NAME = assign(math.max(20, math.floor(assignable_space / 6)))
    local W_PERCENT_TTL = assign(8)
    local W_PERCENT_REL = assign(8)
    local W_COUNT = assign(6)
    local W_TOTAL = assign(10)
    local W_AVG = assign(8)
    local W_MIN = assign(8)
    local W_MAX = assign(10)

    while space_left > 1 do
        W_TOTAL = W_TOTAL + assign(1, false)
        W_TOTAL = W_TOTAL + assign(1, false)
        W_MAX = W_MAX + assign(1, false)
        W_AVG = W_AVG + assign(1, false)
        W_MAX = W_MAX + assign(1, false)
        W_MIN = W_MIN + assign(1, false)
        W_NAME = W_NAME + assign(1, false)
        W_COUNT = W_COUNT + assign(1, false)
    end

    return {
        W_NAME = W_NAME - left_padding - ((depth + 1) * 2),
        W_PERCENT_TTL = W_PERCENT_TTL,
        W_PERCENT_REL = W_PERCENT_REL,
        W_TOTAL = W_TOTAL,
        W_COUNT = W_COUNT,
        W_AVG = W_AVG,
        W_MAX = W_MAX,
        W_MIN = W_MIN,
    }
end

---@param node NuiTree.Node
---@return NuiLine
local function prepare(node, win_width)
    local function get_depth_hl(depth)
        return depth % 2 == 0 and "ProfileReportEven" or "ProfileReportOdd"
    end

    local depth = node:get_depth()
    local hl_group = get_depth_hl(depth)
    local layout = Layout.compute(win_width, depth)

    local line = Line()

    local indents = {}
    for i = 1, depth do
        indents[i] = { "  ", get_depth_hl(i) }
    end

    local arrow = node:has_children()
        and (node:is_expanded() and " " or " ")
        or "  "

    table.insert(indents, { arrow, hl_group })
    local indent_visual_width = #indents * 2

    line:append(Text("", {
        virt_text = indents,
        virt_text_pos = "inline",
    }))

    line:append(string.format("%-" .. layout.W_NAME .. "s ", node.name or ""), hl_group)
    line:append(string.format("%" .. layout.W_PERCENT_TTL .. "s ", string.format("%.2f%%", node.percentage_total * 100)),
        hl_group)
    line:append(string.format("%" .. layout.W_PERCENT_REL .. "s ", string.format("%.2f%%", node.percentage_rel * 100)),
        hl_group)
    line:append(string.format("%" .. layout.W_TOTAL .. "s ", string.format("%.2fms", node.total_duration)), hl_group)
    line:append(string.format("%" .. layout.W_COUNT .. "s ", node.count), hl_group)
    line:append(string.format("%" .. layout.W_AVG .. "s", string.format("%.2fms", node.avg)), hl_group)
    line:append(string.format("%" .. layout.W_MIN .. "s", string.format("%.2fms", node.min)), hl_group)
    line:append(string.format("%" .. layout.W_MAX .. "s", string.format("%.2fms", node.max)), hl_group)
    line:append("  ", hl_group)

    local actual_text_width = indent_visual_width + line:width()
    local remaining = win_width - actual_text_width
    if remaining > 0 then
        line:append(string.rep(" ", remaining), hl_group)
    end

    return line
end

function Profiler:report()
    while #self.stack > 0 do self:stop() end

    local root_total = 0
    for _, c in pairs(self.root.children) do
        root_total = root_total + c.total_duration
    end
    self.root.total_duration = root_total

    vim.cmd("botright vsplit")
    local win = vim.api.nvim_get_current_win()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(win, bufnr)

    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    vim.wo[win].statuscolumn = ""
    vim.wo[win].signcolumn = "no"
    vim.wo[win].foldcolumn = "0"

    local win_width = vim.api.nvim_win_get_width(win)

    local root_nodes = vim.iter(self.root.children):map(build_tree):totable()
    table.insert(root_nodes, 1, NuiTree.Node({ is_header = true }))
    local tree = NuiTree({
        bufnr = bufnr,
        nodes = root_nodes,
        prepare_node = function (node)
            local layout = Layout.compute(win_width, 0)
            local hl = "ProfileReportEven"
            if node.is_header then
                local line = Line()
                line:append("  ", hl)
                line:append(string.format("%-" .. layout.W_NAME .. "s ", "Name"), hl)
                line:append(string.format("%" .. layout.W_PERCENT_TTL .. "s ", "Ttl. %"), hl)
                line:append(string.format("%" .. layout.W_PERCENT_REL .. "s ", "Rel. %"), hl)
                line:append(string.format("%" .. layout.W_TOTAL .. "s ", "Total"), hl)
                line:append(string.format("%" .. layout.W_COUNT .. "s ", "Count"), hl)
                line:append(string.format("%" .. layout.W_AVG .. "s", "Avg"), hl)
                line:append(string.format("%" .. layout.W_MIN .. "s", "Min"), hl)
                line:append(string.format("%" .. layout.W_MAX .. "s", "Max"), hl)
                line:append("  ", hl)

                return line
            else
                return prepare(node, win_width)
            end
        end,
    })

    vim.keymap.set("n", "<CR>", function ()
        local n = tree:get_node()
        if not n then return end
        if n:is_expanded() then n:collapse() else n:expand() end
        tree:render()
    end, { buffer = bufnr, noremap = true, silent = true })


    tree:render()
end

local profiler = Profiler.new()
return profiler
