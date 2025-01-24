if not nixCats("ui.enabled") then
    return
end

for _, file in ipairs(require("utils").dirs(nixCats.configDir .. "/lua/ui")) do
    require("ui." .. file.basename)
end
