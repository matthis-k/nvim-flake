local utils = require("utils")
local Part = require("ui.lib.linepart")

local M = {}

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

M.mode = {
    cache = function (cache, shared)
        for k, v in pairs(modes[vim.api.nvim_get_mode().mode] or { text = "UNKOWN", hl = "StlModeNormal" }) do
            cache[k] = v
        end
        shared.mode_hl = cache.hl
    end,
    text = function (cache)
        return cache.text
    end,
    hl = function (cache)
        return cache.hl
    end,
}

M.filename = {
    hl = "StlSectionB",
    text = function ()
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
                for i, part in ipairs(parts) do
                    if #part > 5 then
                        parts[i] = part:sub(1, 5) .. "…"
                    end
                end
                file = table.concat(parts, "/") .. "/" .. fname
            end
        end
        return file
    end,
}

M.modified = {
    cache = function (lcache, shared)
        lcache.buf = vim.api.nvim_get_current_buf()
    end,
    text = function (lcache, shared)
        if vim.bo[lcache.buf].modified then
            return "modified"
        end
    end,
}

M.readonly = {
    cache = function (lcache, shared)
        lcache.buf = vim.api.nvim_get_current_buf()
    end,
    hl = "@error",
    text = function (lcache, shared)
        if vim.bo[lcache.buf].readonly then
            return "readonly"
        end
    end,
}

M.diagnostics = {
    get_text = function (severity)
        return function ()
            local errors = #vim.diagnostic.get(0, { severity = severity })
            local sign = vim.fn.sign_getdefined("DiagnosticSignError")[1].text
            if errors == 0 then
                return ""
            end
            return string.format("%d %s", errors, utils.utf8sub(sign, 1, 1))
        end
    end,
}

M.diagnostics.errors = {
    hl = vim.fn.sign_getdefined("DiagnosticSignError")[1].texthl,
    text = M.diagnostics.get_text(vim.diagnostic.severity.ERROR),
}
M.diagnostics.warnings = {
    hl = vim.fn.sign_getdefined("DiagnosticSignWarn")[1].texthl,
    text = M.diagnostics.get_text(vim.diagnostic.severity.WARN),
}
M.diagnostics.info = {
    hl = vim.fn.sign_getdefined("DiagnosticSignInfo")[1].texthl,
    text = M.diagnostics.get_text(vim.diagnostic.severity.INFO),
}
M.diagnostics.hint = {
    hl = vim.fn.sign_getdefined("DiagnosticSignHint")[1].texthl,
    text = M.diagnostics.get_text(vim.diagnostic.severity.HINT),
}
M.diagnostics.all = {
    children = {
        Part(M.diagnostics.errors),
        Part(M.diagnostics.warnings),
        Part(M.diagnostics.info),
        Part(M.diagnostics.hints),
    },
    child_sep = Part(" "),
}

M.pos = {
    text = function ()
        local line = vim.fn.line(".")
        local col = vim.fn.col(".")
        return string.format("%03d:%02d", line, col)
    end,
}

M.encoding = {
    text = function ()
        return string.format("%s", vim.bo.fileencoding or "utf-8")
    end,
}

M.filetype = {
    text = function ()
        return string.format("%s", vim.bo.filetype or "none")
    end,
}

return M
