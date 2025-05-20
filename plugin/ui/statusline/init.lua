if not nixCats("ui.statusline") then
    return
end

local profiler = require("profiler")
local ffi = require("ffi")

ffi.cdef [[
  typedef unsigned long long disptick_T;
  extern disptick_T display_tick;
]]

local stl = require("ui.statusline")
local part = require("part")

local last_tick = -1

---@return string
function StatusLine()
    profiler:start({ "stl" })
    local tick = ffi.C.display_tick

    if tick ~= last_tick then
        ---@diagnostic disable-next-line: cast-local-type
        last_tick = tick
        stl.init_cache()
    end

    local result = part.build_string(stl.whole)
    profiler:stop({ "stl" })

    return result
end

vim.o.statusline = "%!v:lua.StatusLine()"
vim.o.laststatus = 3
