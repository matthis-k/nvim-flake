---@class Part.builder.data
---@field hl? string|fun(args:any, ctx:any):string|fun(args:any, ctx:any):(fun(args:any, ctx:any):string)
---@field text? string|fun(args:any, ctx:any):string|fun(args:any, ctx:any):(fun(args:any, ctx:any):string)
---@field name? string|fun(args:any, ctx:any):string|fun(args:any, ctx:any):(fun(args:any, ctx:any):string)
---@field on_click? string|fun(args:any, ctx:any):string|fun(args:any, ctx:any):(fun(args:any, ctx:any):string)
---@field on_click_param? string|fun(args:any, ctx:any):string|fun(args:any, ctx:any):(fun(args:any, ctx:any):string)
---@field children? Part.builder[]|fun(args:any, ctx:any):Part.builder[]|fun(args:any, ctx:any):(fun(args:any, ctx:any):Part.builder[])
---@field child_sep? Part.builder|fun(args:any, ctx:any):Part.builder|fun(args:any, ctx:any):(fun(args:any, ctx:any):Part.builder)
---@field before? Part.builder|fun(args:any, ctx:any):Part.builder|fun(args:any, ctx:any):(fun(args:any, ctx:any):Part.builder)
---@field after? Part.builder|fun(args:any, ctx:any):Part.builder|fun(args:any, ctx:any):(fun(args:any, ctx:any):Part.builder)
---@field ctx? fun(args:any):any|any
---@field build_string? fun(self:Part.instance.data):string
---@field instanciated_cache any<string, Part.instance>

---@class Part.instance.data
---@field ctx? any
---@field args? any
---@field hl? string|fun(args:any, ctx:any):string
---@field text? string|fun(args:any, ctx:any):string
---@field name? string|fun(args:any, ctx:any):string
---@field on_click? string|fun(args:any, ctx:any):string
---@field on_click_param? string|fun(args:any, ctx:any):string
---@field children? Part.instance[]|fun(args:any, ctx:any):Part.instance[]
---@field child_sep? Part.instance|fun(args:any, ctx:any):Part.instance
---@field before? Part.instance
---@field after? Part.instance
---@field build_string? fun(self:Part.instance.data):string

local Part = {}


---@class Part.builder: Part.builder.data
Part.Builder = {}
Part.Builder.__index = Part.Builder
setmetatable(Part.Builder, {
    ---@param _ any
    ---@param data Part.builder.data
    ---@return Part.builder
    __call = function (_, data)
        local obj = data or {}
        obj.instanciated_cache = obj.instanciated_cache or {}
        return setmetatable(obj, Part.Builder)
    end,
})

---@param args any
---@return Part.instance
function Part.Builder:instanciate(args)
    --@type any
    local ctx
    if type(self.ctx) == "function" then
        ctx = self.ctx(args)
    else
        ctx = self.ctx
    end
    local function instanciate_value(val)
        if type(val) == "function" then
            return instanciate_value(val(args, ctx))
        elseif type(val) == "table" then
            if val.instanciate then
                return val:instanciate(args, ctx)
            elseif vim.islist(val) then
                local res = {}
                for idx, child in ipairs(val) do
                    res[idx] = instanciate_value(child)
                end
                return res
            else
                return Part.Builder(val):instanciate(args)
            end
        else
            return val
        end
    end

    local result = Part.Instance(self)
    result.ctx = ctx
    result.args = args

    for key, value in pairs(self) do
        if key == "build_string" then
            result[key] = function (s, a)
                local res = value(s, a)
                if res == nil then
                    return Part.Instance.build_string(s, a)
                else
                    return res
                end
            end
        elseif key ~= "instanciated_cache" then
            local inst = instanciate_value(value)
            result[key] = inst
            if type(value) ~= "function" and key ~= "children" then
                self.instanciated_cache[key] = inst
            end
        end
    end

    return result
end

---@class Part.instance: Part.instance.data
Part.Instance = {}
Part.Instance.__index = Part.Instance
setmetatable(Part.Instance, {
    ---@param _ any
    ---@return Part.instance
    __call = function (_, builder)
        local instance = setmetatable({}, {
            __index = function (_, k)
                local v = builder and builder.instanciated_cache[k]
                return v ~= nil and v or Part.Instance[k]
            end,
        })
        return instance
    end,
})

---@param args any
---@return string
function Part.Instance:build_string(args)
    local hl
    ---@param val nil|string|Part.instance|fun(ctx:any):string|fun(ctx:any):Part.instance|fun(ctx:any):Part.instance[]
    ---@return string
    local function build_value_string(val)
        local result
        if type(val) == "string" then
            result = val
        elseif type(val) == "function" then
            result = build_value_string(val(args))
        elseif type(val) == "table" then
            if val.build_string then
                result = val:build_string(args)
            elseif vim.islist(val) then
                local children_str = ""
                if val and #val > 0 then
                    local sep = build_value_string(self.child_sep)
                    local child_strs = {}
                    for _, child in ipairs(val) do
                        local child_eval = build_value_string(child)
                        if #child_eval > 0 then
                            child_eval = child_eval .. hl
                            table.insert(child_strs, child_eval)
                        end
                    end
                    if #child_strs > 0 then
                        children_str = table.concat(child_strs, sep)
                    end
                    result = children_str
                end
            else
                result = Part.Instance.build_string(val, args)
            end
        end

        return result or ""
    end
    hl = build_value_string(self.hl)
    local text = build_value_string(self.text)
    local before = build_value_string(self.before)
    local after = build_value_string(self.after)
    local on_click = build_value_string(self.on_click)
    local on_click_param = build_value_string(self.on_click_param)

    if #hl > 0 then
        hl = string.format("%%#%s#", hl)
    end

    local children_str = build_value_string(self.children)

    local content = text .. children_str

    before = (#content > 0 and before) or ""
    after = (#content > 0 and after) or ""

    local click_prefix = ""
    local click_suffix = ""
    if #on_click > 0 then
        if on_click_param ~= "" then
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
