local ffi = require("ffi")
local Part = require("part")
local profiler = require("profiler")

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
    profiler:start({ "tabl" })
    local tick = ffi.C.display_tick
    if tick ~= last_tick then
        ---@diagnostic disable-next-line: cast-local-type
        last_tick = tick
        tabline.init_cache()
    end
    local res = Part.build_string(tabline.whole)
    profiler:stop({ "tabl" })
    return res
end

vim.api.nvim_create_augroup("RedrawTabline", { clear = true })
vim.api.nvim_create_autocmd({ "ModeChanged", "DiagnosticChanged" }, {
    group = "RedrawTabline",
    callback = function ()
        vim.cmd.redrawtabline()
    end,
})


vim.o.tabline = "%!v:lua.TabLine()"
vim.o.showtabline = 2
