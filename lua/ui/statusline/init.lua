if not nixCats("ui.statusline") then
    return
end

local utils = require("utils")
local hl = utils.compose_hl

local builder = require("ui.linebuilder")
local component = builder.component
local group = builder.group

---Creates the mode part of the status line
---@return nixovim.ui.line.Part
local function stl_mode()
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

    return component(string.format(" %s ", mode.text), mode.hl)
end

---Creates the filename part of the status line
---@return nixovim.ui.line.Part
local function stl_filename()
    local file = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":.")
    local dir = vim.fn.fnamemodify(file, ":h")
    if file == "" then
        file = "[No Name]"
    else
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
    return component(file, "StlSectionB")
end

---Creates the diagnostic part of the status line
---@return nixovim.ui.line.Part
local function stl_file_diagnostics()
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
        table.insert(
            parts,
            component(string.format("%d %s", errors, utils.utf8sub(signs.error.text, 1, 1)), signs.error.texthl)
        )
    end
    if warnings > 0 then
        table.insert(
            parts,
            component(string.format("%d %s", warnings, utils.utf8sub(signs.warn.text, 1, 1)), signs.warn.texthl)
        )
    end
    if infos > 0 then
        table.insert(
            parts,
            component(string.format("%d %s", infos, utils.utf8sub(signs.info.text, 1, 1)), signs.info.texthl)
        )
    end
    if hints > 0 then
        table.insert(
            parts,
            component(string.format("%d %s", hints, utils.utf8sub(signs.hint.text, 1, 1)), signs.hint.texthl)
        )
    end
    return group(nil, parts, true, false, false)
end

local git_cache = {
    bufmap = {},
    dirs = {},
}

local function git_dir(bufnr)
    local path = vim.api.nvim_buf_get_name(bufnr or 0)
    local git_root = vim.fn.finddir(".git", path .. ";")
    return vim.fn.fnamemodify(git_root, ":p:h:h")
end

local function init_cache(bufnr)
    local git_root = git_dir(bufnr)
    if not git_cache.dirs[git_root] then
        git_cache.bufmap[bufnr] = git_root
        git_cache.dirs[git_root] = {
            branch = nil,
            remote = { ahead = 0, behind = 0, last_fetch = 0 },
            -- status = { added = 0, removed = 0 },
        }

        local head_file = git_root .. "/.git/HEAD"

        local function read_head_file()
            local f = io.open(head_file, "r")
            if f then
                local content = f:read("*l")
                f:close()
                if content then
                    local branch = content:match("ref: refs/heads/(.+)")
                    if branch then
                        git_cache.dirs[git_root].branch = branch
                    else
                        git_cache.dirs[git_root].branch = content:sub(1, 7)
                    end
                    vim.cmd("redrawstatus")
                end
            end
        end

        local function update_git_remote()
            local now = vim.loop.hrtime() / 1e9
            if now - git_cache.dirs[git_root].remote.last_fetch < 300 then
                return
            end
            git_cache.dirs[git_root].remote.last_fetch = now

            local branch = git_cache.dirs[git_root].branch
            if not branch then
                return
            end

            local cmd = { "git", "rev-list", "--left-right", "--count", branch .. "...origin/" .. branch }
            vim.fn.jobstart(cmd, {
                cwd = git_root,
                stdout_buffered = true,
                on_stdout = function (_, data)
                    if data then
                        local output = table.concat(data, "\n")
                        local ahead, behind = output:match("(%d+)%s+(%d+)")
                        git_cache.dirs[git_root].remote.ahead = tonumber(ahead) or 0
                        git_cache.dirs[git_root].remote.behind = tonumber(behind) or 0
                        vim.cmd("redrawstatus")
                    end
                end,
            })
        end

        local head_watcher = vim.loop.new_fs_event()
        if head_watcher then
            head_watcher:start(
                head_file,
                {},
                vim.schedule_wrap(function ()
                    read_head_file()
                end)
            )
        end

        local timer = vim.loop.new_timer()
        if timer then
            timer:start(
                0,
                300000,
                vim.schedule_wrap(function ()
                    update_git_remote()
                end)
            )
        end

        read_head_file()
        update_git_remote()

        git_cache.dirs[git_root].head_watcher = head_watcher
        git_cache.dirs[git_root].remote_timer = timer
    end
end

---Creates the git branch part of the status line
---@return nixovim.ui.line.Part
local function stl_git_branch()
    local bufnr = vim.api.nvim_get_current_buf()
    init_cache(bufnr)
    local git_root = git_cache.bufmap[bufnr]
    if not git_root then
        return {}
    end

    local branch = git_cache.dirs[git_root].branch
    if not branch then return {} end

    return component(string.format(" %s", branch), "StlGitBranch")
end

--[[
---@diagnostic disable-next-line
local function stl_git_status()
    local bufnr = vim.api.nvim_get_current_buf()
    init_cache(bufnr)
    local git_root = git_cache.bufmap[bufnr]
    if not git_root then return {} end

    local status = git_cache.dirs[git_root].status
    local parts = {}
    if status.added > 0 then
        table.insert(parts, { text = string.format(" +%d ", status.added), hl = "StlGitAdded" })
    end
    if status.removed > 0 then
        table.insert(parts, { text = string.format(" -%d ", status.removed), hl = "StlGitDeleted" })
    end
    return { parts = parts }
end
--]]

---Creates the git remote ahead/behind part of the status line
---@return nixovim.ui.line.Part
local function stl_git_remote()
    local bufnr = vim.api.nvim_get_current_buf()
    init_cache(bufnr)
    local git_root = git_cache.bufmap[bufnr]
    if not git_root then
        return {}
    end

    local remote = git_cache.dirs[git_root].remote
    local parts = {}
    if remote.ahead > 0 then
        table.insert(parts, component(string.format("↑%d", remote.ahead), "StlGitRemoteAhead"))
    end
    if remote.behind > 0 then
        table.insert(parts, component(string.format("↓%d", remote.behind), "StlGitRemoteBehind"))
    end
    if remote.behind == 0 and remote.ahead == 0 then
        table.insert(parts, component(string.format("✓", remote.behind), "StlGitBranch"))
    end
    return group(nil, parts, false, false, false)
end

---Creates the cursor position part of the status line
---@return nixovim.ui.line.Part
local function get_line_col()
    local line = vim.fn.line(".")
    local col = vim.fn.col(".")
    return component(string.format("%3d:%-2d", line, col))
end

---Creates the file enconding part of the status line
---@return nixovim.ui.line.Part
local function get_encoding()
    return component(string.format("%s", vim.bo.fileencoding or "utf-8"))
end

---Creates the file type part of the status line
---@return nixovim.ui.line.Part
local function get_filetype()
    return component(string.format("%s", vim.bo.filetype or "none"))
end

---Creates status line format string
---@return string
function StatusLine()
    local line = group(nil, {
        group("StlSectionA", { stl_mode() }, false, false, false),
        group("StlSectionB", {
            stl_git_branch(),
            stl_git_remote(),
            stl_filename(),
            stl_file_diagnostics(),
        }),
        group("StlSectionC", {}),
        group("StlSectionC", { component("%=") }),
        group("StlSectionB", {
            get_filetype(),
            get_encoding(),
        }),
        group("StlSectionA", { get_line_col() }),
    }, false, false, false)
    return builder.part_to_str(line)
end

local loaded = false
if not loaded then
    vim.api.nvim_set_hl(0, "StlSectionA", hl({ link = "@method", reverse = true }))
    vim.api.nvim_set_hl(0, "StlSectionB", hl({ link = "Visual" }))
    vim.api.nvim_set_hl(0, "StlSectionC", hl({ link = "Normal" }))

    vim.api.nvim_set_hl(0, "StlModeNormal", hl({ link = "@method", reverse = true, bold = true }))
    vim.api.nvim_set_hl(0, "StlModeVisual", hl({ link = "@keyword", reverse = true, bold = true }))
    vim.api.nvim_set_hl(0, "StlModeInsert", hl({ link = "@string", reverse = true, bold = true }))
    vim.api.nvim_set_hl(0, "StlModeReplace", hl({ link = "@character", reverse = true, bold = true }))
    vim.api.nvim_set_hl(0, "StlModeCommand", hl({ link = "@constant", reverse = true, bold = true }))
    vim.api.nvim_set_hl(0, "StlModeTerminalInsert", hl({ link = "StlModeInsert", reverse = true, bold = true }))
    vim.api.nvim_set_hl(0, "StlModeTerminalNormal", hl({ link = "StlModeNormal", reverse = true, bold = true }))

    vim.api.nvim_set_hl(0, "StlFilename", hl({ link = "Field" }))

    vim.api.nvim_set_hl(0, "StlDiagnosticError", hl({ fg = "DiagnosticError", bg = "Visual", bold = true }))
    vim.api.nvim_set_hl(0, "StlDiagnosticWarn", hl({ fg = "DiagnosticWarn", bg = "Visual" }))
    vim.api.nvim_set_hl(0, "StlDiagnosticInfo", hl({ fg = "DiagnosticInfo", bg = "Visual" }))
    vim.api.nvim_set_hl(0, "StlDiagnosticHint", hl({ fg = "DiagnosticHint", bg = "Visual" }))

    vim.api.nvim_set_hl(0, "StlGitBranch", hl({ fg = "@method", bg = "StlSectionB", bold = true }))
    vim.api.nvim_set_hl(0, "StlGitAdded", hl({ fg = "Added", bg = "StlSectionB" }))
    vim.api.nvim_set_hl(0, "StlGitDeleted", hl({ fg = "Removed", bg = "StlSectionB" }))

    vim.api.nvim_set_hl(0, "StlGitRemoteAhead", hl({ fg = "@class", bg = "StlSectionB" }))
    vim.api.nvim_set_hl(0, "StlGitRemoteBehind", hl({ fg = "@class", bg = "StlSectionB" }))
    vim.o.statusline = "%!v:lua.StatusLine()"
    vim.o.laststatus = 3

    vim.api.nvim_create_augroup("StlRedraw", { clear = true })
    vim.api.nvim_create_autocmd("DiagnosticChanged", {
        group = "StlRedraw",
        pattern = "*",
        callback = function ()
            local buffers = vim.api.nvim_list_bufs()
            if #buffers > 0 then
                vim.cmd("redrawstatus")
            end
        end,
    })
end
