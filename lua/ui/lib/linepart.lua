_G.click_handlers = {}
local EMPTY = ""
---@class PartData
---@field hl? string|fun(cache:table, shared:table):string?
---@field text? string|fun(cache:table, shared:table):string?
---@field on_click? string|fun(cache:table, shared:table):string?
---@field on_click_param? string|fun(cache:table, shared:table):string?
---@field children? Part[]|fun(cache:table, shared:table):Part[]?
---@field child_sep? Part|fun(cache:table, shared:table):Part?
---@field before? Part|fun(cache:table, shared:table):Part?
---@field after? Part|fun(cache:table, shared:table):Part?
---@field opts? PartDataOpts|fun(cache:table, shared:table):PartDataOpts?
---@field cache? fun(local:table,shared:table)

---@class PartDataOpts
---@field smart_before_after? boolean|fun(self:Part?):boolean
---@field ignore_empty_child? boolean|fun(self:Part?):boolean

---@class Part
---@field data PartData
local Part = {}
setmetatable(Part, {
    __call = function (_, args)
        local data = type(args) == "string" and { text = args }
            or type(args) == "function" and args()
            or args
            or {}
        return setmetatable({ data = data }, Part)
    end,
})
Part.__index = Part

--- Sets the children field.
---@param children Part[]|fun(...:any):Part[]
---@return Part
function Part:children(children)
    self.data.children = children
    return self
end

--- Sets the hl field.
---@param hl string|fun(...:any):string
---@return Part
function Part:hl(hl)
    self.data.hl = hl
    return self
end

-- Additional builder methods can be defined similarly:

--- Sets the text field.
---@param text string|fun(...:any):string
---@return Part
function Part:text(text)
    self.data.text = text
    return self
end

--- Sets the on_click field.
---@param on_click string|fun(...:any):string
---@return Part
function Part:on_click(on_click)
    self.data.on_click = on_click
    return self
end

--- Sets the on_click_param field.
---@param on_click_param string|fun(...:any):string
---@return Part
function Part:on_click_param(on_click_param)
    self.data.on_click_param = on_click_param
    return self
end

--- Sets the child_sep field.
---@param child_sep string|Part|fun(...:any):Part
---@return Part
function Part:child_sep(child_sep)
    self.data.child_sep = type(child_sep) == "string" and Part(child_sep) or child_sep
    return self
end

--- Sets the before field.
---@param before string|Part|fun(...:any):Part
---@return Part
function Part:before(before)
    self.data.before = type(before) == "string" and Part(before) or before
    return self
end

--- Sets the after field.
---@param after string|Part|fun(...:any):Part
---@return Part
function Part:after(after)
    self.data.after = type(after) == "string" and Part(after) or after
    return self
end

--- Sets the cache field.
---@param cache fun(lcache:table, shared: table)
---@return Part
function Part:cache(cache)
    self.data.cache = cache
    return self
end

--- Sets the cache field.
---@param cache fun(lcache:table, shared: table)
---@return Part
function Part:cache_append(cache)
    local old_cache = self.data.cache
    self.data.cache = function (lcache, shared)
        if old_cache then
            old_cache(lcache, shared)
        end
        cache(lcache, shared)
    end
    return self
end

function Part:cache_prepend(cache)
    local old_cache = self.data.cache
    self.data.cache = function (lcache, shared)
        cache(lcache, shared)
        if old_cache then
            old_cache(lcache, shared)
        end
    end
    return self
end

function Part:init_caches(local_cache, shared_cache)
    local function init_cache(part)
        if type(part) == "table" and part.data and part.data.cache then
            part.data.cache(local_cache, shared_cache)
        end
    end
    init_cache(self)
    init_cache(self.data.before)
    if self.data.children then
        local children = type(self.data.children) == "function" and (self.data.children(local_cache, shared_cache) or {}) or self.data.children
        if children and #children > 0 then
            init_cache(self.data.child_sep)
            vim.iter(children):each(init_cache)
        end
    end
    init_cache(self.data.after)
end

--- Evaluates the Part and returns a string.
--- @return string
function Part:eval(shared_cache)
    local data = self.data or {}
    opts = type(data.opts) == "function" and data.opts() or data.opts or {}
    local ignore_empty_child = opts.ignore_empty_child ~= nil and opts.ignore_empty_child or true
    local smart_before_after = opts.smart_before_after ~= nil and opts.smart_before_after or true


    local local_cache = {}
    local shared_cache = shared_cache or {}
    self:init_caches(local_cache, shared_cache)

    local function eval_value(val)
        if type(val) == "function" then
            return val(local_cache, shared_cache)
        elseif type(val) == "table" and val.eval then
            return val:eval(shared_cache) or EMPTY
        else
            return val or EMPTY
        end
    end


    local hl = eval_value(data.hl) or EMPTY
    local text_val = eval_value(data.text) or EMPTY
    local before = eval_value(data.before) or EMPTY
    local after = eval_value(data.after) or EMPTY
    local on_click = eval_value(data.on_click) or EMPTY
    local on_click_param = eval_value(data.on_click_param) or EMPTY

    local res = {}
    res.hl = #hl > 0 and string.format("%%#%s#", hl) or EMPTY

    -- Process children: evaluate each child and optionally ignore empty results.
    res.children_str = EMPTY
    if data.children then
        local children = type(data.children) == "function" and (data.children(local_cache, shared_cache) or {} or {}) or data.children
        if children and #children > 0 then
            local sep = EMPTY
            if data.child_sep then
                sep = eval_value(data.child_sep)
            end
            local child_strs = vim.iter(children)
                :map(function (child)
                    child_eval = eval_value(child)
                    if #child_eval > 0 then
                        child_eval = child_eval .. res.hl
                    end
                    return child_eval
                end)
                :filter(function (s) return #s > 0 end)
                :totable()
            if #child_strs > 0 then
                res.children_str = table.concat(child_strs, sep)
            end
        end
    end

    res.own_content = text_val .. res.children_str
    res.before = (smart_before_after and #res.own_content > 0 and before) or (not smart_before_after and before) or EMPTY
    res.after = (smart_before_after and #res.own_content > 0 and after) or (not smart_before_after and after) or EMPTY

    res.click_prefix = EMPTY
    res.click_suffix = EMPTY
    if #on_click > 0 then
        if on_click_param ~= EMPTY then
            res.click_prefix = string.format("%%%s@%s@", on_click_param, on_click)
        else
            res.click_prefix = string.format("%%@%s@", on_click)
        end
        res.click_suffix = "%T"
    end


    if #res.own_content > 0 then
        return res.click_prefix .. res.hl .. res.before .. res.own_content .. res.after .. res.click_suffix
    else
        return EMPTY
    end
end

return Part
