local M = {}

function M.lua_files(dir)
    local scanner = vim.uv.fs_scandir(dir)
    local result = {}
    if scanner then
        while true do
            local name, _ = vim.uv.fs_scandir_next(scanner)
            if not name then
                break
            end
            local basename = name:match("^(.+)%.lua$")
            if not basename then
                break
            end
            table.insert(result, { basename = basename, path = dir .. "/" .. name })
        end
    end
    return result
end

function M.dirs(dir)
    local scanner = vim.uv.fs_scandir(dir)
    local result = {}
    if scanner then
        while true do
            local name, t = vim.uv.fs_scandir_next(scanner)
            if not name then
                break
            end
            if t == "directory" then
                table.insert(result, { basename = name, path = dir .. "/" .. name })
            end
        end
    end
    return result
end

---@param args vim.api.keyset.highlight
---@return vim.api.keyset.highlight A composed highlight with given options
function M.compose_hl(args)
    local opts = vim.deepcopy(args) or {}
    ---@type vim.api.keyset.highlight
    local res = {}
    if opts.fg and type(opts.fg) == "string" then
        local hexcode = opts.fg:match("#%x%x%x%x?%x?%x?%x?%x?")
        if hexcode then
            res.fg = hexcode
        else
            local base = vim.api.nvim_get_hl(0, { name = opts.fg, link = false }) or {}
            res.fg = base.fg
        end
    end
    if opts.bg and type(opts.bg) == "string" then
        local hexcode = opts.bg:match("#%x%x%x%x?%x?%x?%x?%x?")
        if hexcode then
            res.bg = hexcode
        else
            local base = vim.api.nvim_get_hl(0, { name = opts.bg, link = false }) or {}
            res.bg = base.bg
        end
    end
    if (not opts.fg) and not opts.bg and opts.link then
        res = vim.api.nvim_get_hl(0, { name = opts.link, link = false }) or {}
        opts.link = nil
    end
    ---@type  vim.api.keyset.highlight
    return vim.tbl_deep_extend("keep", res, opts)
end

function M.utf8sub(str, start, stop)
    if stop < start then
        return ""
    end
    local utf8_char_indices = vim.str_utf_pos(str)
    local utf8len = #utf8_char_indices
    if utf8len <= stop then
        return str
    end
    return str:sub(utf8_char_indices[start], utf8_char_indices[stop + 1] - 1)
end

function M.validate(subject, schema, opts)
    local strict = opts and opts.strict or true
    if strict then
        for key, _ in pairs(subject) do
            if not schema[key] then
                return false
            end
        end
    end
    local valid, _ = pcall(
        vim.validate,
        vim.iter(schema)
        :map(function (key, val)
            return { subject[key], val }
        end)
        :totable()
    )
    return valid
end

return M
