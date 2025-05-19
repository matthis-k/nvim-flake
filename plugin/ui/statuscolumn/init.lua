if not nixCats("ui.statuscolumn") then
    return
end

local ffi = require("ffi")
local Part = require("part")
local profiler = require("profiler")

ffi.cdef [[
  typedef unsigned long long disptick_T;
  extern disptick_T display_tick;
]]

local last_tick = -1

local stc = require("ui.statuscolumn")

---Defines my status column
---@return string
function StatusColumn()
    profiler:start({ "stc" })
    local tick = ffi.C.display_tick

    if tick ~= last_tick then
        ---@diagnostic disable-next-line: cast-local-type
        last_tick = tick
        stc.init_cache()
    end

    local result = Part.build_string(stc.whole)
    profiler:stop({ "stc" })
    return result
end

vim.o.statuscolumn = "%!v:lua.StatusColumn()"
vim.o.numberwidth = 4
