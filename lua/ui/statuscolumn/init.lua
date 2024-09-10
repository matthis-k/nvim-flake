if not nixCats("ui.statuscolumn") then
    return
end
local utf8sub = require("utils").utf8sub
local builder = require("ui.linebuilder")
local group = builder.group
local component = builder.component

---Implemetns the number colomn with _some_ support for vims options
---@param win integer The window id of the column drawn
---@param line integer What line we are at
---@return nixovim.ui.line.Component
local function number_column(win, line)
    if line < 1
        or ((not vim.wo[win].relativenumber) and (not vim.wo[win].number)) then
        return component()
    end
    local width = math.max(vim.wo[win].numberwidth, #tostring(vim.fn.line("w$", win)) + 1)
    local is_focused = win == vim.api.nvim_get_current_win()
    local num_str
    local hl
    if vim.v.relnum == 0 and vim.wo.relativenumber and is_focused then
        num_str = string.format("%-" .. tostring(width) .. "d", line)
        hl = "StcCurrentLineNumber"
    else
        num_str = string.format("%" .. tostring(width) .. "d", is_focused and vim.v.relnum or line)
        hl = "StcLineNumber"
    end
    return component(num_str, hl)
end

---Shows sign with highest priority matching the filter
---@param win integer The window id of the column drawn
---@param line integer What line we are at
---@param filter? any
---@param opts? any
---@return nixovim.ui.line.Component
local function signs(win, line, filter, opts)
    local width = opts and opts.width or 2
    filter = filter or {}
    local namespaces = vim.iter(vim.api.nvim_get_namespaces())
        :map(function (name, id)
            return name:match(filter.namespace or ".*") and id
        end)
        :totable()
    local extmarks = vim.iter(namespaces)
        :map(function (namespace)
            return vim.api.nvim_buf_get_extmarks(
                vim.api.nvim_win_get_buf(win),
                namespace,
                { line - 1, 0 },
                { line - 1, -1 },
                { details = true }
            )
        end)
        :flatten()
        :totable()
    local extmark = vim.iter(extmarks)
        :map(function (extmark)
            return extmark[4]
        end)
        :fold({ priority = 0 }, function (acc, cur)
            if acc.priority < cur.priority then
                acc = cur
            end
            return acc
        end)
    local text = (" "):rep(width or 2, "")
    if extmark and extmark.sign_text then
        text = utf8sub(extmark.sign_text, 1, width)
    end
    return component(text, extmark.sign_hl_group)
end

---Defines my status column
---@return string
function StatusColumn()
    local win = vim.g.statusline_winid
    local line = vim.v.lnum
    local stc = group("StcLineNumber", {
        signs(win, line, { namespace = "vim%.lsp%..+%..+%/diagnostic%/signs" }, { width = 2 }),
        number_column(win, line),
        signs(win, line, { namespace = "gitsigns_signs_.*" }, { width = 1 }),
    }, false, false, false)

    if vim.wo[vim.g.statusline_winid].statuscolumn then
        return builder.part_to_str(stc)
    else
        return ""
    end
end

local loaded = false
if not loaded then
    local hl = require("utils").compose_hl

    vim.api.nvim_set_hl(0, "StcSignColumn", hl({ link = "SignColumn" }))
    vim.api.nvim_set_hl(0, "StcFoldColumn", hl({ link = "FoldColumn" }))
    vim.api.nvim_set_hl(0, "StcLineNumber", hl({ link = "LineNr" }))
    vim.api.nvim_set_hl(0, "StcCurrentLineNumber", hl({ link = "CursorLine", bold = true }))

    vim.o.statuscolumn = "%!v:lua.StatusColumn()"
    vim.o.numberwidth = 1
end
