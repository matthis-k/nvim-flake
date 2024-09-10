local utils = require("utils")
local M = {}

---@alias nixovim.ui.line.Part nixovim.ui.line.Component | nixovim.ui.line.ComponentGroup

---@param part nixovim.ui.line.Part
---@return string
function M.part_to_str(part)
    local res = ""
    if M.is_component(part) then
        ---@cast part nixovim.ui.line.Component
        res = M.component_to_str(part)
    elseif M.is_group(part) then
        ---@cast part nixovim.ui.line.ComponentGroup
        res = M.group_to_str(part)
    end
    return res
end

---@class nixovim.ui.line.Component
---@field hl? string
---@field text? string
---@field click_handler? string

function M.is_component(tbl)
    return utils.validate(tbl, {
        hl = { "string", "nil" },
        text = { "string", "nil" },
        click_handler = { "string", "nil" },
    }, { strict = true })
end

function M.is_group(tbl)
    return utils.validate(tbl, {
        hl = { "string", "nil" },
        parts = { "table", "nil" },
        after = { "table", "nil" },
        before = { "table", "nil" },
        separator = { "table", "nil" },
    }, { strict = true })
end

---Create a String that is part of a line
---@param component nixovim.ui.line.Component
---@return string
function M.component_to_str(component)
    local res = ""
    if component.hl then
        res = res .. string.format("%%#%s#", component.hl)
    end
    if component.text then
        res = res .. string.format("%s", component.text)
    end
    return res
end

---@class nixovim.ui.line.ComponentGroup
---@field parts? nixovim.ui.line.Part[]
---@field before? nixovim.ui.line.Part
---@field after? nixovim.ui.line.Part
---@field separator? nixovim.ui.line.Part
---@field hl? string

---Create a String that is part of a line
---@param group nixovim.ui.line.ComponentGroup
---@return string
function M.group_to_str(group)
    local res = ""

    if group.hl then
        res = res .. M.part_to_str({ hl = group.hl })
    end
    if group.before then
        res = res .. M.part_to_str(group.before)
    end


    local parts_as_str = table.concat(vim.iter(group.parts or {}):map(function (part)
            return M.part_to_str(part)
        end)
        :filter(function (part_str)
            return #part_str > 0
        end)
        :totable(), group.separator and M.part_to_str(group.separator) or "")
    res = res .. parts_as_str

    if group.after then
        res = res .. M.part_to_str(group.after)
    end

    return res
end

---Create a compnent from text and hl
---@param text? string
---@param hl? string
---@return nixovim.ui.line.Component
function M.component(text, hl)
    return {
        hl = hl,
        text = text,
    }
end

---Create a group from some parameters
---@param hl? string
---@param parts? nixovim.ui.line.Part[]
---@param sep? boolean|nixovim.ui.line.Part|string
---@param before? boolean|nixovim.ui.line.Part
---@param after? boolean|nixovim.ui.line.Part
---@return nixovim.ui.line.ComponentGroup
function M.group(hl, parts, sep, before, after)
    local function default(arg)
        if arg == nil or arg == true then
            return M.component(" ")
        elseif arg == false then
            return nil
        elseif type(arg) == "string" then
            return M.component(arg)
        else
            return arg
        end
    end
    return {
        hl = hl,
        parts = parts,
        separator = default(sep),
        before = default(before),
        after = default(after),
    }
end

return M
