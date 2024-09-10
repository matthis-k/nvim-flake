if not nixCats("ui.enabled") then
    return
end

for _, file in ipairs(require("utils").dirs(vim.fn.stdpath("config") .. "/lua/ui")) do
    require("ui." .. file.basename)
end
