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
    local res = Part.build_string(tabline.whole)
    return res
end

vim.api.nvim_create_augroup("RedrawTabline", { clear = true })
vim.api.nvim_create_autocmd({ "ModeChanged", "DiagnosticChanged" }, {
    group = "RedrawTabline",
    callback = function ()
        vim.cmd.redrawtabline()
    end,
})


_G.Ui = _G.Ui or {}
_G.Ui.TabLine = TabLine
vim.o.tabline = "%!v:lua.Ui.TabLine()"
vim.o.showtabline = 2
