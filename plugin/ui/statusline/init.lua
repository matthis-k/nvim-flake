if not nixCats("ui.statusline") then
    return
end

local ffi = require("ffi")

ffi.cdef [[
  typedef unsigned long long disptick_T;
  extern disptick_T display_tick;
]]

local stl = require("ui.statusline")
local part = require("part")
local prof = require("profiler")("tabline")

local last_tick = -1

---@return string
function StatusLine()
    prof:start("call")
    local tick = ffi.C.display_tick

    prof:start("cache")
    if tick ~= last_tick then
        ---@diagnostic disable-next-line: cast-local-type
        last_tick = tick
        stl.init_cache()
    end
    prof:stop("cache")

    local result = part.build_string(stl.whole)

    prof:stop("call")
    return result
end

vim.o.statusline = "%!v:lua.StatusLine()"
vim.o.laststatus = 3
