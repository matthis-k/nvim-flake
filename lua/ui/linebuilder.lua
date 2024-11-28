_G.click_handlers = {}
local M = {}

---@class nixovim.ui.line.Part
---@field text? string
---@field hl? string
---@field on_click? string
---@field on_click_param? string -- This represents minwid
---@field separator nixovim.ui.line.Part
---@field before nixovim.ui.line.Part
---@field after nixovim.ui.line.Part
---@field [number] nixovim.ui.line.Part

---@class nixovim.ui.line.part.Opts
---@field separator? string|nixovim.ui.line.Part|boolean
---@field before? string|nixovim.ui.line.Part|boolean
---@field after? string|nixovim.ui.line.Part|boolean

---Convert a part to a string
---@param part nixovim.ui.line.Part
---@return string
function M.part_to_str(part)
    local res = ""
    if not part then return res end

    local hl_string = (part.hl and string.format("%%#%s#", part.hl) or "")

    res = res .. hl_string

    res = res .. M.part_to_str(part.before)

    res = res .. (part.text or "")

    local sub_parts = {}
    for _, sub_part in ipairs(part) do
        local sub_res = M.part_to_str(sub_part)
        if sub_part.hl then
            sub_res = sub_res .. hl_string
        end
        if #sub_res > 0 then
            table.insert(sub_parts, sub_res)
        end
    end

    if #sub_parts > 0 then
        local sep = M.part_to_str(part.separator)
        res = res .. table.concat(sub_parts, sep)
    end

    if type(part.after) == "string" then
        res = res .. part.after
    elseif type(part.after) == "table" then
        res = res .. M.part_to_str(part.after)
    end

    if part.on_click then
        local param_str = type(part.on_click_param) == "string" and part.on_click_param or tostring(part.on_click_param)
        local click_str = part.on_click_param
            and string.format("%%%s@%s@", param_str, part.on_click)
            or string.format("%%@%s@", part.on_click)
        res = click_str .. res .. "%T"
    end

    return res
end

---Create a part
---@param parts? string|nixovim.ui.line.Part[]|string
---@param opts? nixovim.ui.line.Part|boolean|string|nixovim.ui.line.part.Opts
---@param hl? string
---@param on_click? string
---@param on_click_param? string
---@return nixovim.ui.line.Part
function M.part(parts, opts, hl, on_click, on_click_param)
    ---@param value nixovim.ui.line.Part|boolean|string|nil
    ---@return nixovim.ui.line.Part|nil
    local function default_value(value)
        if value == nil or value == true then
            return { text = " " }
        elseif type(value) == "string" then
            return { text = value }
        elseif value == false then
            return { text = "" }
        elseif type(value) == "table" then
            return value
        end
    end
    local res = type(parts) == "string" and { text = parts } or parts or {}
    local tmp
    if opts == nil then
        tmp = true
    else
        tmp = opts
    end
    if type(opts) ~= "table" then
        tmp = { separator = tmp, before = tmp, after = tmp }
    end
    local defaulted_opts = vim.iter(tmp):fold({}, function (acc, k, val)
        if k == "before" or k == "separator" or k == "after" then
            acc[k] = default_value(val)
        else
            acc[k] = val
        end
        return acc
    end)

    defaulted_opts.hl = hl
    defaulted_opts.on_click = on_click
    defaulted_opts.on_click_param = on_click_param

    res = vim.tbl_deep_extend("force", res, defaulted_opts or {})
    return res
end

return M
