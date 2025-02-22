if not nixCats("ui.enabled") then
    return
end

for _, file in ipairs(require("utils").dirs(nixCats.configDir .. "/lua/ui")) do
    local status, err = pcall(require, "ui." .. file.basename)
end
