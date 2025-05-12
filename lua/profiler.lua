local Profiler = {}
Profiler.__index = Profiler

local function ms() return vim.loop.hrtime() / 1e6 end

local function new_node(name, parent)
    return {
        name     = name,
        total    = 0,
        count    = 0,
        start_ts = nil,
        closed   = false,
        parent   = parent,
        children = {},
    }
end

Profiler.__call = function (_, name)
    return setmetatable({ root = new_node(name or "total"), stack = {} }, Profiler)
end
setmetatable(Profiler, Profiler)

function Profiler:_close_node(node)
    if not node or node.closed or not node.start_ts then return end
    node.total  = node.total + (ms() - node.start_ts)
    node.closed = true
end

function Profiler:start(label)
    local parent  = #self.stack > 0 and self.stack[#self.stack] or self.root
    local node    = new_node(label, parent)
    node.start_ts = ms()
    node.count    = 1
    table.insert(parent.children, node)
    table.insert(self.stack, node)
end

function Profiler:stop(label)
    if #self.stack == 0 then return end
    local idx = #self.stack
    while idx > 0 do
        local node = self.stack[idx]
        self:_close_node(node)
        table.remove(self.stack, idx)
        if label == nil or node.name == label then
            break
        end
        idx = idx - 1
    end
end

local NuiTree = require("nui.tree")
local Line    = require("nui.line")
local Text    = require("nui.text")

function Profiler:_aggregate(node)
    local map = {}
    for _, c in ipairs(node.children) do
        local e = map[c.name]
        if not e then
            e = { name = c.name, total = 0, count = 0, children = {} }
            map[c.name] = e
        end
        e.total = e.total + c.total
        e.count = e.count + c.count
        for _, gc in ipairs(c.children) do
            table.insert(e.children, gc)
        end
    end
    for _, v in pairs(map) do
        local tmp = self:_aggregate({ children = v.children })
        v.children = tmp.children
    end
    local list = {}
    for _, v in pairs(map) do table.insert(list, v) end
    table.sort(list, function (a, b) return a.total > b.total end)
    return { name = node.name, total = node.total, count = node.count, children = list }
end

local function make_nodes(tbl, root_total)
    local function dir_to_node(t)
        local children = {}
        for _, c in ipairs(t.children) do
            table.insert(children, dir_to_node(c))
        end
        if #children > 0 then
            table.insert(children, 1, NuiTree.Node({ is_header = true }, {}))
        end
        return NuiTree.Node({
            name  = t.name,
            total = t.total,
            count = t.count,
            pct   = (root_total > 0) and t.total / root_total * 100 or 0,
        }, children)
    end

    local baseline_header = NuiTree.Node({ is_header = true, baseline = true }, {})
    return { baseline_header, dir_to_node(tbl) }
end

local function prepare(node)
    local W_NAME, W_PERCENT, W_TOTAL, W_COUNT, W_AVG = 18, 10, 10, 10, 10
    if node.is_header then
        local depth  = node:get_depth()
        local indent = node.baseline and "  " or string.rep("  ", depth - 1) .. "  "

        local line   = Line()
        line:append(indent)
        line:append(Text(string.format("%-" .. W_NAME .. "s ", "Name"), "Title"))
        line:append(Text(string.format("%" .. W_PERCENT .. "s ", "Percent"), "Title"))
        line:append(Text(string.format("%" .. W_TOTAL .. "s ", "Total"), "Title"))
        line:append(Text(string.format("%" .. W_COUNT .. "s ", "Count"), "Title"))
        line:append(Text(string.format("%" .. W_AVG .. "s", "Avg"), "Title"))
        return line
    end

    local depth = node:get_depth()
    local arrow = node:has_children()
        and (node:is_expanded() and " " or " ")
        or "  "

    local pct = node.pct or 0
    local avg = (node.count and node.count > 0) and node.total / node.count or 0

    local line = Line()
    -- indent
    line:append(Text("", {
        virt_text     = { { string.rep("  ", depth - 1), nil } },
        virt_text_pos = "inline",
    }))
    -- arrow/icon
    line:append(Text("", {
        virt_text     = { { arrow, node:has_children() and "Directory" or "Normal" } },
        virt_text_pos = "inline",
    }))
    -- columns
    line:append(Text(string.format("%-" .. W_NAME .. "s ", node.name or ""), "TSVariable"))
    line:append(Text(string.format("%" .. W_PERCENT .. "s ", string.format("%.2f%%", pct)), "Number"))
    line:append(Text(string.format("%" .. W_TOTAL .. "s ", string.format("%.2fms", node.total)), "Number"))
    line:append(Text(string.format("%" .. W_COUNT .. "s ", tostring(node.count)), "Number"))
    line:append(Text(string.format("%" .. W_AVG .. "s", string.format("%.2fms", avg)), "Number"))
    return line
end

function Profiler:report()
    while #self.stack > 0 do self:stop() end
    local root_total = 0; for _, c in ipairs(self.root.children) do root_total = root_total + c.total end
    self.root.total = root_total
    local agg = self:_aggregate(self.root)

    vim.cmd("botright vsplit")
    local win   = vim.api.nvim_get_current_win()
    local bufnr = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_win_set_buf(win, bufnr)

    vim.wo[win].number         = false
    vim.wo[win].relativenumber = false
    vim.wo[win].statuscolumn   = ""
    vim.wo[win].signcolumn     = "no"
    vim.wo[win].foldcolumn     = "0"

    local tree                 = NuiTree({
        bufnr        = bufnr,
        prepare_node = prepare,
        nodes        = make_nodes(agg, root_total),
    })
    tree:render()

    vim.keymap.set("n", "<CR>", function ()
        local n = tree:get_node()
        if not n then return end
        if n:is_expanded() then n:collapse() else n:expand() end
        tree:render()
    end, { buffer = bufnr, noremap = true, silent = true })
end

return Profiler
