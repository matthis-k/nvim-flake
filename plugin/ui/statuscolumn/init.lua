if not nixCats("ui.statuscolumn") then
    return
end

local ffi = require("ffi")

ffi.cdef [[
  typedef unsigned long long disptick_T;
  extern disptick_T display_tick;
]]

local last_tick = -1

local stc = require("ui.statuscolumn")
local total_calls = 0
local total_time_ns = 0
local total_cache_time_ns = 0
local total_eval_time_ns = 0
local total_redraws = 0

---Defines my status column
---@return string
function StatusColumn()
    local start = vim.uv.hrtime()
    local tick = ffi.C.display_tick
    if tick ~= last_tick then
        total_redraws = total_redraws + 1
        last_tick = tick
        local cache_start = vim.uv.hrtime()
        stc.init_cache()
        total_cache_time_ns = total_cache_time_ns + (vim.uv.hrtime() - cache_start)
    end
    local res = ""
    local line = stc.get(vim.g.statusline_winid, vim.v.lnum)
    local eval_start = vim.uv.hrtime()
    if line then
        res = line:build_string()
    end
    local eval_duration = vim.uv.hrtime() - eval_start
    total_eval_time_ns = total_eval_time_ns + eval_duration

    total_time_ns = total_time_ns + (vim.uv.hrtime() - start)
    total_calls = total_calls + 1
    return res
end

function STLAVG()
    local avg_per_call = (total_time_ns / total_calls) / 1e6
    local avg_per_redraw = (total_time_ns / total_redraws) / 1e6
    local avg_eval = (total_eval_time_ns / total_calls) / 1e6

    vim.print(table.concat({
        ("total calls: %d"):format(total_calls),
        ("total redraws: %d"):format(total_redraws),
        ("total time: %.fms"):format(total_time_ns / 1e6),
        ("time/call: %.2fms"):format(avg_per_call),
        ("time/redraw: %.2fms"):format(avg_per_redraw),
        ("time/eval: %.2fms"):format(avg_eval),
        ("evals/redraw: %.2f"):format(total_calls / math.max(total_redraws, 1)),
        ("caching time/redraw: %.2fms"):format(total_cache_time_ns / math.max(total_redraws, 1) / 1e6),
    }, "\n"
    ))
end

vim.o.statuscolumn = "%!v:lua.StatusColumn()"
vim.o.numberwidth = 4
