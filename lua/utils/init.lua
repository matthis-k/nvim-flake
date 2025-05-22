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

local ffi = require("ffi")

ffi.cdef [[
typedef struct {
  int start;
  int end;
  int level;
  int lines;
} FoldInfo;

FoldInfo fold_info(void *win, int lnum);
void* find_window_by_handle(int handle, int *error);
]]


local function get_fold_info(winid, lnum)
    if type(winid) ~= "number" or type(lnum) ~= "number" then
        return nil
    end

    local err = ffi.new("int[1]")
    local cwin = ffi.C.find_window_by_handle(winid, err)
    if err[0] ~= 0 or cwin == nil then
        return nil
    end

    local ok, result = pcall(ffi.C.fold_info, cwin, lnum)
    if not ok then
        return nil
    end
    return result
end

function M.foldexpr(lnum, win)
    local target_win = win or vim.api.nvim_get_current_win()
    return get_fold_info(target_win, lnum)
end

local reverse_lookup = {}

local highlight_fields = {
    "fg", "bg", "sp",
    "bold", "italic", "underline", "undercurl", "strikethrough", "reverse",
    "nocombine", "standout",
}

local function serialize_highlight(tbl)
    local parts = {}
    for _, key in ipairs(highlight_fields) do
        local val = tbl[key]
        if val == nil or val == false then
            table.insert(parts, "")
        else
            local sanitized = tostring(val):gsub("#", "")
            table.insert(parts, sanitized)
        end
    end
    return "AutoHl" .. table.concat(parts, "IxI")
end

--- Create or reuse a highlight group for a given spec
--- @param hl_def table
--- @return string: highlight group name
function M.auto_hl(hl_def)
    local key = serialize_highlight(hl_def)

    if reverse_lookup[key] then
        return key
    end

    vim.api.nvim_set_hl(0, key, hl_def)

    reverse_lookup[key] = true
    return key
end

function M.to_hex(color)
    if not color or type(color) ~= "number" then return nil end
    return string.format("#%06x", color)
end

return M
