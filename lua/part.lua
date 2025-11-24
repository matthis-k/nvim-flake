local Part = {}

---@class PartSpec
---@field name? string
---@field text? string|fun():string
---@field hl? string|fun():string
---@field before? string|fun():string|PartSpec|fun():PartSpec
---@field after? string|fun():string|PartSpec|fun():PartSpec
---@field children? PartSpec[]|fun():PartSpec[]
---@field child_sep? string|fun():string|PartSpec|fun():PartSpec
---@field on_click? string|fun():string
---@field on_click_param? string|fun():string
---@field build_string? fun(part: PartSpec): string

--- Build a string from a part
---@param part PartSpec
---@return string
function Part.build_string(part)
    ---@param val any
    ---@return string
    local function eval(val)
        if type(val) == "string" then
            return val
        elseif type(val) == "function" then
            return eval(val())
        elseif type(val) == "table" then
            if val.build_string then
                return val.build_string(val)
            else
                return Part.build_string(val)
            end
        end
        return tostring(val or "")
    end


    local hl = eval(part.hl)
    local text = eval(part.text)
    local before = eval(part.before)
    local after = eval(part.after)
    local on_click = eval(part.on_click)
    local on_click_param = eval(part.on_click_param)

    if #hl > 0 then
        hl = string.format("%%#%s#", hl)
    end

    local child_strs = {}
    local children = type(part.children) == "function" and part.children()
        or (part.children or {})
    for _, child in ipairs(children) do
        local child_str = eval(child)
        if #child_str > 0 then
            table.insert(child_strs, child_str .. hl)
        end
    end
    local children_str = table.concat(child_strs, eval(part.child_sep))



    local content = text .. children_str
    before = (#content > 0 and before) or ""
    after = (#content > 0 and after) or ""

    local click_prefix, click_suffix = "", ""
    if #on_click > 0 then
        if #on_click_param > 0 then
            click_prefix = string.format("%%%s@%s@", on_click_param, on_click)
        else
            click_prefix = string.format("%%@%s@", on_click)
        end
        click_suffix = "%T"
    end

    if #content > 0 then
        return click_prefix .. hl .. before .. content .. after .. click_suffix
    else
        return ""
    end
end

return Part
