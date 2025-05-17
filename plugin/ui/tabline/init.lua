local ffi = require("ffi")
local Part = require("part")

ffi.cdef [[
  typedef unsigned long long disptick_T;
  extern disptick_T display_tick;
]]

local last_tick = -1

if not nixCats("ui.tabline") then
    return
end

local tabline = require("ui.tabline")

---@return string
function TabLine()
    local tick = ffi.C.display_tick
    if tick ~= last_tick then
        ---@diagnostic disable-next-line: cast-local-type
        last_tick = tick
        tabline.init_cache()
    end
    return Part.build_string(tabline.whole)
end

vim.o.tabline = "%!v:lua.TabLine()"
vim.o.showtabline = 2
