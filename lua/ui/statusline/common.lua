local utils = require("utils")
local builder = require("ui.linebuilder")
local part = builder.part

local M = {}

---Creates the mode part of the status line
---@return nixovim.ui.line.Part
function M.mode()
    local modes = {
        ["n"] = { text = "NORMAL", hl = "StlModeNormal" },
        ["no"] = { text = "O-PENDING", hl = "StlModeNormal" },
        ["nov"] = { text = "O-PENDING", hl = "StlModeNormal" },
        ["noV"] = { text = "O-PENDING", hl = "StlModeNormal" },
        ["no\22"] = { text = "O-PENDING", hl = "StlModeNormal" },
        ["niI"] = { text = "NORMAL", hl = "StlModeNormal" },
        ["niR"] = { text = "NORMAL", hl = "StlModeNormal" },
        ["niV"] = { text = "NORMAL", hl = "StlModeNormal" },
        ["v"] = { text = "VISUAL", hl = "StlModeVisual" },
        ["vs"] = { text = "VISUAL", hl = "StlModeVisual" },
        ["V"] = { text = "V-LINE", hl = "StlModeVisual" },
        ["Vs"] = { text = "V-LINE", hl = "StlModeVisual" },
        ["\22"] = { text = "V-BLOCK", hl = "StlModeVisual" },
        ["\22s"] = { text = "V-BLOCK", hl = "StlModeVisual" },
        ["s"] = { text = "SELECT", hl = "StlModeVisual" },
        ["S"] = { text = "S-LINE", hl = "StlModeVisual" },
        ["\19"] = { text = "S-BLOCK", hl = "StlModeVisual" },
        ["i"] = { text = "INSERT", hl = "StlModeInsert" },
        ["ic"] = { text = "INSERT", hl = "StlModeInsert" },
        ["ix"] = { text = "INSERT", hl = "StlModeInsert" },
        ["R"] = { text = "REPLACE", hl = "StlModeReplace" },
        ["Rc"] = { text = "REPLACE", hl = "StlModeReplace" },
        ["Rx"] = { text = "REPLACE", hl = "StlModeReplace" },
        ["Rv"] = { text = "V-REPLACE", hl = "StlModeReplace" },
        ["Rvc"] = { text = "V-REPLACE", hl = "StlModeReplace" },
        ["Rvx"] = { text = "V-REPLACE", hl = "StlModeReplace" },
        ["c"] = { text = "COMMAND", hl = "StlModeCommand" },
        ["cv"] = { text = "EX", hl = "StlModeCommand" },
        ["ce"] = { text = "EX", hl = "StlModeCommand" },
        ["r"] = { text = "REPLACE", hl = "StlModeReplace" },
        ["rm"] = { text = "MORE", hl = "StlModeReplace" },
        ["r?"] = { text = "CONFIRM", hl = "StlModeReplace" },
        ["!"] = { text = "SHELL", hl = "StlModeCommand" },
        ["t"] = { text = "T-INSERT", hl = "StlModeTerminalInsert" },
        ["nt"] = { text = "T-NORMAL", hl = "StlModeTerminalNormal" },
    }
    local mode = modes[vim.api.nvim_get_mode().mode] or { text = "UNKOWN", hl = "StlModeNormal" }

    return part(string.format(" %s ", mode.text), nil, mode.hl)
end

---Creates the filename part of the status line
---@return nixovim.ui.line.Part
function M.filename()
    local file = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":.")
    local dir = vim.fn.fnamemodify(file, ":h")
    if file == "" then
        file = "[No Name]"
    else
        if #file > 70 then
            local fname = vim.fn.fnamemodify(file, ":t")
            local parts = vim.split(dir, "/")
            if #parts > 3 then
                parts = { parts[1], "...", parts[#parts - 1], parts[#parts] }
            end
            for i, prt in ipairs(parts) do
                if #prt > 5 then
                    parts[i] = prt:sub(1, 5) .. "…"
                end
            end
            file = table.concat(parts, "/") .. "/" .. fname
        end
    end
    return part(file, false, "StlSectionB")
end

---Creates the diagnostic part of the status line
---@return nixovim.ui.line.Part
function M.diagnostics()
    local errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
    local warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
    local infos = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
    local hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
    local function get_sign(sign_name, default_text, default_hl)
        local sign = vim.fn.sign_getdefined(sign_name)[1]
        sign.texthl = default_hl
        sign.text = sign.text or default_text
        return sign
    end

    local signs = {
        error = get_sign("DiagnosticSignError", "E", "StlDiagnosticError"),
        warn = get_sign("DiagnosticSignWarn", "W", "StlDiagnosticWarn"),
        info = get_sign("DiagnosticSignInfo", "I", "StlDiagnosticInfo"),
        hint = get_sign("DiagnosticSignHint", "H", "StlDiagnosticHint"),
    }

    local parts = {}
    if errors > 0 then
        table.insert(parts,
            part(string.format("%d %s", errors, utils.utf8sub(signs.error.text, 1, 1)), false, signs.error.texthl)
        )
    end
    if warnings > 0 then
        table.insert(parts,
            part(string.format("%d %s", warnings, utils.utf8sub(signs.warn.text, 1, 1)), false, signs.warn.texthl))
    end
    if infos > 0 then
        table.insert(parts,
            part(string.format("%d %s", infos, utils.utf8sub(signs.info.text, 1, 1)), false, signs.info.texthl))
    end
    if hints > 0 then
        table.insert(parts,
            part(string.format("%d %s", hints, utils.utf8sub(signs.hint.text, 1, 1)), false, signs.hint.texthl))
    end
    return part(parts, { before = false, after = false, separator = true })
end

---Creates the cursor position part of the status line
---@return nixovim.ui.line.Part
function M.pos()
    local line = vim.fn.line(".")
    local col = vim.fn.col(".")
    return part(string.format("%3d:%-2d", line, col), false)
end

---Creates the file enconding part of the status line
---@return nixovim.ui.line.Part
function M.encoding()
    return part(string.format("%s", vim.bo.fileencoding or "utf-8"), false)
end

---Creates the file type part of the status line
---@return nixovim.ui.line.Part
function M.filetype()
    return part(string.format("%s", vim.bo.filetype or "none"), false)
end

return M
