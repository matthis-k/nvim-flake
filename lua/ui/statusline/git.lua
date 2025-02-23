local Part = require("ui.lib.linepart")

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
        on_stderr = function (_, _)
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

M.timer = vim.uv.new_timer()
if M.timer then
    M.timer:start(
        0,
        300000,
        vim.schedule_wrap(function ()
            M.update_remotes()
        end))
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


-- Git branch: shows the current branch name.
M.branch = Part()
    :hl("StlGitBranch")
    :text(function ()
        local bufnr = vim.api.nvim_get_current_buf()
        local git_status = vim.b[bufnr].gitsigns_status_dict
        if not git_status then return "" end
        return git_status.head or ""
    end)

M.status = {}
M.status.added = Part()
    :hl("StlGitAdded")
    :text(function ()
        local bufnr = vim.api.nvim_get_current_buf()
        local git_status = vim.b[bufnr].gitsigns_status_dict
        if not git_status or not (git_status.added and git_status.added > 0) then return "" end
        return string.format("+%d", git_status.added)
    end)

M.status.changed = Part()
    :hl("StlGitChanged")
    :text(function ()
        local bufnr = vim.api.nvim_get_current_buf()
        local git_status = vim.b[bufnr].gitsigns_status_dict
        if not git_status or not (git_status.changed and git_status.changed > 0) then return "" end
        return string.format("~%d", git_status.changed)
    end)

M.status.removed = Part()
    :hl("StlGitDeleted")
    :text(function ()
        local bufnr = vim.api.nvim_get_current_buf()
        local git_status = vim.b[bufnr].gitsigns_status_dict
        if not git_status or not (git_status.removed and git_status.removed > 0) then return "" end
        return string.format("-%d", git_status.removed)
    end)

M.status.all = Part()
    :children({
        M.status.added,
        M.status.changed,
        M.status.removed,
    })

-- Git remote: shows ahead/behind counts and a check mark when in sync.
M.remote = {}
M.remote.ahead = Part()
    :hl("StlGitRemoteAhead")
    :text(function ()
        local bufnr = vim.api.nvim_get_current_buf()
        local git_status = vim.b[bufnr].gitsigns_status_dict
        if not git_status then return "" end
        if not M.cache[git_status.root] then M.update_remotes() end
        local remote = M.cache[git_status.root]
        if remote.error or not (remote.ahead and remote.ahead > 0) then return "" end
        return string.format("↑%d", remote.ahead)
    end)

M.remote.behind = Part()
    :hl("StlGitRemoteBehind")
    :text(function ()
        local bufnr = vim.api.nvim_get_current_buf()
        local git_status = vim.b[bufnr].gitsigns_status_dict
        if not git_status then return "" end
        if not M.cache[git_status.root] then M.update_remotes() end
        local remote = M.cache[git_status.root]
        if remote.error or not (remote.behind and remote.behind > 0) then return "" end
        return string.format("↓%d", remote.behind)
    end)

M.remote.up_to_date = Part()
    :hl("StlGitBranch")
    :text(function ()
        local bufnr = vim.api.nvim_get_current_buf()
        local git_status = vim.b[bufnr].gitsigns_status_dict
        if not git_status then return "" end
        if not M.cache[git_status.root] then M.update_remotes() end
        local remote = M.cache[git_status.root]
        if remote.error then return "" end
        if remote.ahead == 0 and remote.behind == 0 then
            return "✓"
        end
        return ""
    end)

M.remote.all = Part()
    :children({
        M.remote.ahead,
        M.remote.behind,
        M.remote.up_to_date,
    })

-- Git icon: a static icon.
M.icon = Part()
    :text(function ()
        local bufnr = vim.api.nvim_get_current_buf()
        local git_status = vim.b[bufnr].gitsigns_status_dict
        if not git_status then return "" end
        return ""
    end)
    :hl("StlGitBranch")

-- All git parts combined.
M.all = Part()
    :children({
        M.icon,
        M.branch,
        M.remote.all,
        M.status.all,
    })
    :child_sep(" ")

return M
