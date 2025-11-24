local utils       = require("utils")
local devicons    = require("nvim-web-devicons")

local M           = {}

_G.click_handlers = _G.click_handlers or {}

local modes       = {
    ["n"]   = { text = "NORMAL", hl = "StlModeNormal" },
    ["no"]  = { text = "O‑PENDING", hl = "StlModeNormal" },
    ["nov"] = { text = "O‑PENDING", hl = "StlModeNormal" },
    ["noV"] = { text = "O‑PENDING", hl = "StlModeNormal" },
    ["\22"] = { text = "V‑BLOCK", hl = "StlModeVisual" },
    ["niI"] = { text = "NORMAL", hl = "StlModeNormal" },
    ["niR"] = { text = "NORMAL", hl = "StlModeNormal" },
    ["niV"] = { text = "NORMAL", hl = "StlModeNormal" },
    ["v"]   = { text = "VISUAL", hl = "StlModeVisual" },
    ["vs"]  = { text = "VISUAL", hl = "StlModeVisual" },
    ["V"]   = { text = "V‑LINE", hl = "StlModeVisual" },
    ["Vs"]  = { text = "V‑LINE", hl = "StlModeVisual" },
    ["s"]   = { text = "SELECT", hl = "StlModeVisual" },
    ["S"]   = { text = "S‑LINE", hl = "StlModeVisual" },
    ["\19"] = { text = "S‑BLOCK", hl = "StlModeVisual" },
    ["i"]   = { text = "INSERT", hl = "StlModeInsert" },
    ["ic"]  = { text = "INSERT", hl = "StlModeInsert" },
    ["ix"]  = { text = "INSERT", hl = "StlModeInsert" },
    ["R"]   = { text = "REPLACE", hl = "StlModeReplace" },
    ["Rc"]  = { text = "REPLACE", hl = "StlModeReplace" },
    ["Rx"]  = { text = "REPLACE", hl = "StlModeReplace" },
    ["Rv"]  = { text = "V‑REPLACE", hl = "StlModeReplace" },
    ["Rvc"] = { text = "V‑REPLACE", hl = "StlModeReplace" },
    ["Rvx"] = { text = "V‑REPLACE", hl = "StlModeReplace" },
    ["c"]   = { text = "COMMAND", hl = "StlModeCommand" },
    ["cv"]  = { text = "EX", hl = "StlModeCommand" },
    ["ce"]  = { text = "EX", hl = "StlModeCommand" },
    ["r"]   = { text = "REPLACE", hl = "StlModeReplace" },
    ["rm"]  = { text = "MORE", hl = "StlModeReplace" },
    ["r?"]  = { text = "CONFIRM", hl = "StlModeReplace" },
    ["!"]   = { text = "SHELL", hl = "StlModeCommand" },
    ["t"]   = { text = "T‑INSERT", hl = "StlModeTerminalInsert" },
    ["nt"]  = { text = "T‑NORMAL", hl = "StlModeTerminalNormal" },
}

local buf_cache   = {}

function M.init_cache()
    buf_cache = {}
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) then
            local file = vim.api.nvim_buf_get_name(bufnr)
            if file == "" then file = "[No Name]" end
            local short = file
            if #file > 70 and file ~= "[No Name]" then
                local fname = vim.fn.fnamemodify(file, ":t")
                local dir = vim.fn.fnamemodify(file, ":h")
                local parts = vim.split(dir, "/")
                if #parts > 3 then
                    parts = { parts[1], "...", parts[#parts - 1], parts[#parts] }
                end
                for i, p in ipairs(parts) do
                    if #p > 5 then parts[i] = p:sub(1, 5) .. "…" end
                end
                short = table.concat(parts, "/") .. "/" .. fname
            end
            local icon, icon_hl = devicons.get_icon(file, vim.fn.fnamemodify(file, ":e"), { default = true })
            buf_cache[bufnr] = {
                icon = icon or "",
                icon_hl = icon_hl or "Normal",
                filepath = short,
            }
        end
    end
end

function M.mode_info()
    return modes[vim.api.nvim_get_mode().mode] or { text = "UNKNOWN", hl = "StlModeNormal" }
end

local function get_sign(name, fallback)
    local s  = vim.fn.sign_getdefined(name)[1] or {}
    s.text   = (s.text ~= "") and s.text or fallback
    s.texthl = (s.texthl ~= "") and s.texthl or "DiagnosticDefault"
    return s
end

local Git     = {}

M.mode        = {
    name   = "mode",
    before = " ",
    after  = " ",
    hl     = function () return M.mode_info().hl end,
    text   = function () return M.mode_info().text end,
}

Git.cache     = Git.cache or {}

local fetched = {}
local function get_ahead_behind(git)
    local ok, res = pcall(function ()
        local line = vim.fn.system({ "git", "rev-list", "--left-right", "--count", git.head .. "..origin/" .. git.head },
            git.root)
        local ahead, behind = line:match("(%d+)%s+(%d+)")
        return { ahead = tonumber(ahead) or 0, behind = tonumber(behind) or 0 }
    end)
    return ok and res or { error = "No remote" }
end

function Git.update()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        local git = vim.b[bufnr].gitsigns_status_dict
        if git and not vim.list_contains(fetched, git.root) then
            Git.cache[git.root] = get_ahead_behind(git)
            table.insert(fetched, git.root)
        end
    end
end

local timer = vim.uv.new_timer()
if timer then
    timer:start(0, 300000, vim.schedule_wrap(Git.update))
end

Git.icon = {
    text = function ()
        return vim.b[vim.api.nvim_get_current_buf()].gitsigns_status_dict and "" or ""
    end,
    hl   = "StlGitBranch",
}

Git.branch = {
    text = function ()
        local gs = vim.b[vim.api.nvim_get_current_buf()].gitsigns_status_dict
        return (gs and gs.head) or ""
    end,
    hl   = "StlGitBranch",
}

local function diff_counter(key, hl)
    return {
        hl   = hl,
        text = function ()
            local gs = vim.b[vim.api.nvim_get_current_buf()].gitsigns_status_dict
            local n  = gs and gs[key]
            return (n and n > 0) and
                string.format("%s%d", key == "added" and "+" or (key == "removed" and "-" or "~"), n) or ""
        end,
    }
end

Git.status = {
    added   = diff_counter("added", "StlGitAdded"),
    changed = diff_counter("changed", "StlGitChanged"),
    removed = diff_counter("removed", "StlGitDeleted"),
}
Git.status.all = {
    children = { Git.status.added, Git.status.changed, Git.status.removed },
}

local function remote_counter(dir, symbol, hl)
    return {
        hl   = hl,
        text = function ()
            local gs = vim.b[vim.api.nvim_get_current_buf()].gitsigns_status_dict
            if not gs then return "" end
            if not Git.cache[gs.root] then Git.update() end
            local remote = Git.cache[gs.root]
            if remote.error or not remote[dir] or remote[dir] == 0 then return "" end
            return string.format("%s%d", symbol, remote[dir])
        end,
    }
end

Git.remote = {
    ahead  = remote_counter("ahead", "↑", "StlGitRemoteAhead"),
    behind = remote_counter("behind", "↓", "StlGitRemoteBehind"),
    sync   = {
        hl   = "StlGitBranch",
        text = function ()
            local gs = vim.b[vim.api.nvim_get_current_buf()].gitsigns_status_dict
            if not gs then return "" end
            if not Git.cache[gs.root] then Git.update() end
            local r = Git.cache[gs.root]
            if r.error then return "" end
            return (r.ahead == 0 and r.behind == 0) and "✓" or ""
        end,
    },
}
Git.remote.all = { children = { Git.remote.ahead, Git.remote.behind, Git.remote.sync } }

Git.all = {
    name      = "git",
    children  = { Git.icon, Git.branch, Git.remote.all, Git.status.all },
    child_sep = " ",
}

M.filename = {
    name = "filename",
    child_sep = " ",
    children = function ()
        local b = buf_cache[vim.api.nvim_get_current_buf()] or {}
        return {
            { hl = b.icon_hl,     text = b.icon },
            { hl = "StlSectionB", text = b.filepath },
        }
    end,
}

M.modified = {
    name = "modified",
    text = function () return vim.bo.modified and "modified" or "" end,
}

M.readonly = {
    name = "readonly",
    hl   = "@error",
    text = function () return vim.bo.readonly and "readonly" or "" end,
}

local diag_names = {
    [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
    [vim.diagnostic.severity.WARN]  = "DiagnosticSignWarn",
    [vim.diagnostic.severity.INFO]  = "DiagnosticSignInfo",
    [vim.diagnostic.severity.HINT]  = "DiagnosticSignHint",
}

local function diag_part(sev)
    local sign = get_sign(diag_names[sev], "?")
    return {
        hl   = sign.texthl,
        text = function ()
            local n = #vim.diagnostic.get(0, { severity = sev })
            return (n > 0) and string.format("%d %s", n, utils.utf8sub(sign.text, 1, 1)) or ""
        end,
    }
end

M.diagnostics = {
    errors   = diag_part(vim.diagnostic.severity.ERROR),
    warnings = diag_part(vim.diagnostic.severity.WARN),
    info     = diag_part(vim.diagnostic.severity.INFO),
    hints    = diag_part(vim.diagnostic.severity.HINT),
}
M.diagnostics.all = {
    name      = "diagnostics",
    children  = {
        M.diagnostics.errors,
        M.diagnostics.warnings,
        M.diagnostics.info,
        M.diagnostics.hints,
    },
    child_sep = " ",
}

M.pos = {
    name = "pos",
    text = function ()
        return string.format("%03d:%02d", vim.fn.line("."), vim.fn.col("."))
    end,
}

M.encoding = {
    name = "encoding",
    text = function () return vim.bo.fileencoding ~= "" and vim.bo.fileencoding or "utf-8" end,
}
M.filetype = {
    name = "filetype",
    text = function () return vim.bo.filetype ~= "" and vim.bo.filetype or "none" end,
}

M.left = {
    hl        = "StlSectionB",
    before    = " ",
    after     = " ",
    child_sep = " ",
    children  = {
        Git.all,
        M.filename,
        {
            hl = "StlSectionB",
            before = "[",
            after = "]",
            child_sep = " ",
            children = { M.modified, M.readonly },
        },
        M.diagnostics.all,
    },
}

M.right = {
    hl        = "StlSectionB",
    before    = " ",
    after     = " ",
    child_sep = " ",
    children  = { M.filetype, M.encoding },
}

M.whole = {
    hl       = "StlSectionC",
    children = {
        M.mode,
        M.left,
        { text = "%=" },
        M.right,
        {
            before   = " ",
            after    = " ",
            hl       = function () return M.mode_info().hl end,
            children = { M.pos },
        },
    },
}

return M
