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

M.highlights = setmetatable({}, {
    __index = function (_, key)
        return setmetatable(vim.api.nvim_get_hl(0, { name = key, link = false }), nil)
    end,
})

function M.utf8len(str)
    return #vim.str_utf_pos(str)
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

function M.foldexpr(lnum, win)
    local old_lnum = vim.v.lnum
    if lnum then
        vim.v.lnum = lnum
    end
    local res = vim.fn.eval(vim.wo[win or vim.v.windowid].foldexpr)
    vim.v.lnum = old_lnum
    return tostring(res)
end

return M
