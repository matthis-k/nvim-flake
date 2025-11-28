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

---Defines my status column
---@return string
function StatusColumn()
    local tick = ffi.C.display_tick

    if tick ~= last_tick then
        ---@diagnostic disable-next-line: cast-local-type
        last_tick = tick
        stc.init_cache()
    end

    local result = Part.build_string(stc.whole)
    return result
end

_G.Ui = _G.Ui or {}
_G.Ui.StatusColumn = StatusColumn
vim.o.statuscolumn = "%!v:lua.Ui.StatusColumn()"
vim.o.numberwidth = 4

local augroup = vim.api.nvim_create_augroup("stc_cache", { clear = true })

vim.api.nvim_create_autocmd("WinClosed", {
    group = augroup,
    callback = function (event)
        stc.clear(event.match)
    end,
})

vim.api.nvim_create_autocmd("WinResized", {
    group = augroup,
    callback = function ()
        stc.init_cache()
    end,
})

vim.api.nvim_create_autocmd("OptionSet", {
    group = augroup,
    pattern = { "number", "relativenumber", "numberwidth", "foldcolumn", "signcolumn" },
    callback = function (event)
        if event.scope == "global" then
            stc.init_cache()
        else
            stc.refresh(vim.api.nvim_get_current_win())
        end
    end,
})
