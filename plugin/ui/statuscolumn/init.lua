if not nixCats("ui.statuscolumn") then
    return
end

local ffi = require("ffi")
local Part = require("part")

ffi.cdef [[
  typedef unsigned long long disptick_T;
  extern disptick_T display_tick;
]]

local last_tick = -1

local stc = require("ui.statuscolumn")
local prof = require("profiler")("statuscolumn")

---Defines my status column
---@return string
function StatusColumn()
    prof:start("call")
    local tick = ffi.C.display_tick

    prof:start("cache")
    if tick ~= last_tick then
        ---@diagnostic disable-next-line: cast-local-type
        last_tick = tick
        stc.init_cache()
    end
    prof:stop("cache")

    local result = Part.build_string(stc.whole)

    prof:stop("call")
    return result
end

vim.o.statuscolumn = "%!v:lua.StatusColumn()"
vim.o.numberwidth = 4
