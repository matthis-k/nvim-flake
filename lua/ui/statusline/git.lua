local builder = require("ui.linebuilder")
local part = builder.part

local M = {}
M.cache = M.cache or {}

local function get_ahead_behind(git_info)
    local cmd = { "git", "rev-list", "--left-right", "--count", git_info.head .. "...origin/" .. git_info.head }
    local res = { ahead = 0, behind = 0 }
    vim.fn.jobstart(cmd, {
        cwd = git_info.root,
        stdout_buffered = true,
        on_stdout = function (_, data)
            if data then
                local output = table.concat(data, "\n")
                local ahead, behind = output:match("(%d+)%s+(%d+)")
                res.ahead = tonumber(ahead) or 0
                res.behind = tonumber(behind) or 0
            end
        end,
        on_stderr = function (_, err)
            res.error = "No remote"
        end,
        on_exit = function (_, exit_code)
            if exit_code ~= 0 then
                res.error = "No remote"
            end
        end,
    })
    return res
end

local fetched = {}
function M.update_remotes()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        local git_info = vim.b[bufnr].gitsigns_status_dict
        if not git_info then
            goto next_buffer
        end

        if not vim.list_contains(fetched, git_info.head) then
            M.cache[git_info.root] = get_ahead_behind(git_info)
            table.insert(fetched, git_info.root)
        end

        ::next_buffer::
    end
end

M.timer = vim.loop.new_timer()
if M.timer then
    M.timer:start(
        0,
        300000,
        vim.schedule_wrap(function ()
            M.update_remotes()
        end)
    )
end


vim.api.nvim_create_augroup("UpdateGitCache", { clear = true })
vim.api.nvim_create_autocmd("BufReadPost", {
    group = "UpdateGitCache",
    callback = function (ev)
        local git_info = vim.b[ev.buf].gitsigns_status_dict
        if not git_info then return end
        M.cache[git_info.root] = get_ahead_behind(git_info)
        table.insert(fetched, git_info.root)
    end,
})


---Creates the git branch part of the status line
---@return nixovim.ui.line.Part
function M.branch()
    local bufnr = vim.api.nvim_get_current_buf()
    local git_status = vim.b[bufnr].gitsigns_status_dict
    if not git_status then return {} end
    local branch = git_status.head

    return part(branch, false, "StlGitBranch")
end

---Creates the git status part of the status line
---@return nixovim.ui.line.Part
function M.status()
    local bufnr = vim.api.nvim_get_current_buf()
    local git_status = vim.b[bufnr].gitsigns_status_dict
    if not git_status then return {} end

    local parts = {}
    if git_status.added and git_status.added > 0 then
        table.insert(parts, part(string.format("+%d", git_status.added), false, "StlGitAdded"))
    end
    if git_status.changed and git_status.changed > 0 then
        table.insert(parts, part(string.format("~%d", git_status.changed), false, "StlGitChanged"))
    end
    if git_status.removed and git_status.removed > 0 then
        table.insert(parts, part(string.format("-%d", git_status.removed), false, "StlGitDeleted"))
    end
    return part(parts, { before = true, after = false, separator = true })
end

--]]

---Creates the git remote ahead/behind part of the status line
---@return nixovim.ui.line.Part
function M.remote()
    local bufnr = vim.api.nvim_get_current_buf()
    local git_status = vim.b[bufnr].gitsigns_status_dict
    if not git_status then
        return {}
    end

    if not M.cache[git_status.root] then M.update_remotes() end
    local remote = M.cache[git_status.root]
    local parts = {}
    if remote.error then return part("", false) end
    if remote.ahead > 0 then
        table.insert(parts, part(string.format("↑%d", remote.ahead), false, "StlGitRemoteAhead"))
    end
    if remote.behind > 0 then
        table.insert(parts, part(string.format("↓%d", remote.behind), false, "StlGitRemoteBehind"))
    end
    if remote.behind == 0 and remote.ahead == 0 then
        table.insert(parts, part(string.format("✓", remote.behind), false, "StlGitBranch"))
    end
    return part(parts, { before = false, after = true, separator = true })
end

function M.icon()
    local bufnr = vim.api.nvim_get_current_buf()
    local git_status = vim.b[bufnr].gitsigns_status_dict
    if not git_status then return {} end
    -- this some how still uses 2 spaces, there fore
    --some before after magic instead of separators
    return part("")
end

function M.all()
    return part(
        { M.icon(), M.remote(), M.branch(), M.status() },
        false, "StlGitBranch"
    )
end

return M
