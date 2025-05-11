local utils   = require("utils")

local Part    = require("part")
local Builder = Part.Builder
local M       = {}

local modes   = {
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

M.mode        = Builder({
    before = " ",
    after  = " ",
    hl     = function () return M.mode_info().hl end,
    text   = function () return M.mode_info().text end,
})

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

Git.icon = Builder({
    text = function ()
        return vim.b[vim.api.nvim_get_current_buf()].gitsigns_status_dict and "" or ""
    end,
    hl   = "StlGitBranch",
})

Git.branch = Builder({
    text = function ()
        local gs = vim.b[vim.api.nvim_get_current_buf()].gitsigns_status_dict
        return (gs and gs.head) or ""
    end,
    hl   = "StlGitBranch",
})

local function diff_counter(key, hl)
    return Builder({
        hl   = hl,
        text = function ()
            local gs = vim.b[vim.api.nvim_get_current_buf()].gitsigns_status_dict
            local n  = gs and gs[key]
            return (n and n > 0) and
                string.format("%s%d", key == "added" and "+" or (key == "removed" and "-" or "~"), n) or ""
        end,
    })
end

Git.status = {
    added   = diff_counter("added", "StlGitAdded"),
    changed = diff_counter("changed", "StlGitChanged"),
    removed = diff_counter("removed", "StlGitDeleted"),
}
Git.status.all = Builder({ children = { Git.status.added, Git.status.changed, Git.status.removed } })

local function remote_counter(dir, symbol, hl)
    return Builder({
        hl   = hl,
        text = function ()
            local gs = vim.b[vim.api.nvim_get_current_buf()].gitsigns_status_dict
            if not gs then return "" end
            if not Git.cache[gs.root] then Git.update() end
            local remote = Git.cache[gs.root]
            if remote.error or not remote[dir] or remote[dir] == 0 then return "" end
            return string.format("%s%d", symbol, remote[dir])
        end,
    })
end

Git.remote = {
    ahead  = remote_counter("ahead", "↑", "StlGitRemoteAhead"),
    behind = remote_counter("behind", "↓", "StlGitRemoteBehind"),
    sync   = Builder({
        hl   = "StlGitBranch",
        text = function ()
            local gs = vim.b[vim.api.nvim_get_current_buf()].gitsigns_status_dict
            if not gs then return "" end
            if not Git.cache[gs.root] then Git.update() end
            local r = Git.cache[gs.root]
            if r.error then return "" end
            return (r.ahead == 0 and r.behind == 0) and "✓" or ""
        end,
    }),
}
Git.remote.all = Builder({ children = { Git.remote.ahead, Git.remote.behind, Git.remote.sync } })

Git.all = Builder({
    children  = { Git.icon, Git.branch, Git.remote.all, Git.status.all },
    child_sep = " ",
})

M.filename = Builder({
    hl   = "StlSectionB",
    text = function ()
        local file = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":.")
        if file == "" then return "[No Name]" end
        if #file > 70 then
            local fname = vim.fn.fnamemodify(file, ":t")
            local dir   = vim.fn.fnamemodify(file, ":h")
            local parts = vim.split(dir, "/")
            if #parts > 3 then parts = { parts[1], "...", parts[#parts - 1], parts[#parts] } end
            for i, p in ipairs(parts) do if #p > 5 then parts[i] = p:sub(1, 5) .. "…" end end
            file = table.concat(parts, "/") .. "/" .. fname
        end
        return file
    end,
})

M.modified = Builder({
    text = function () return vim.bo.modified and "modified" or "" end,
})

M.readonly = Builder({
    hl   = "@error",
    text = function () return vim.bo.readonly and "readonly" or "" end,
})

local diag_names = {
    [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
    [vim.diagnostic.severity.WARN]  = "DiagnosticSignWarn",
    [vim.diagnostic.severity.INFO]  = "DiagnosticSignInfo",
    [vim.diagnostic.severity.HINT]  = "DiagnosticSignHint",
}

local function diag_part(sev)
    local sign = get_sign(diag_names[sev], "?")
    return Builder({
        hl   = sign.texthl,
        text = function ()
            local n = #vim.diagnostic.get(0, { severity = sev })
            return (n > 0) and string.format("%d %s", n, utils.utf8sub(sign.text, 1, 1)) or ""
        end,
    })
end

M.diagnostics = {
    errors   = diag_part(vim.diagnostic.severity.ERROR),
    warnings = diag_part(vim.diagnostic.severity.WARN),
    info     = diag_part(vim.diagnostic.severity.INFO),
    hints    = diag_part(vim.diagnostic.severity.HINT),
}
M.diagnostics.all = Builder({
    children  = {
        M.diagnostics.errors,
        M.diagnostics.warnings,
        M.diagnostics.info,
        M.diagnostics.hints,
    },
    child_sep = " ",
})

M.pos = Builder({
    text = function ()
        return string.format("%03d:%02d", vim.fn.line("."), vim.fn.col("."))
    end,
})

M.encoding = Builder({ text = function () return vim.bo.fileencoding ~= "" and vim.bo.fileencoding or "utf-8" end })
M.filetype = Builder({ text = function () return vim.bo.filetype ~= "" and vim.bo.filetype or "none" end })

M.left = Builder({
    hl        = "StlSectionB",
    before    = " ",
    after     = " ",
    child_sep = " ",
    children  = {
        Git.all,
        M.filename,
        Builder({ before = "[", after = "]", child_sep = " ", children = { M.modified, M.readonly } }),
        M.diagnostics.all,
    },
})

M.right = Builder({
    hl        = "StlSectionB",
    before    = " ",
    after     = " ",
    child_sep = " ",
    children  = { M.filetype, M.encoding },
})

M.whole = Builder({
    hl       = "StlSectionC",
    children = {
        M.mode,
        M.left,
        Builder({ text = "%=" }),
        M.right,
        Builder({
            before   = " ",
            after    = " ",
            hl       = function () return M.mode_info().hl end,
            children = { M.pos },
        }),
    },
})

return M
