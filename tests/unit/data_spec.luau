local data = require("../../src/data")

local function unique(check, items, field, label)
    local seen = {}
    for _, item in ipairs(items) do
        local value = item[field]
        check(type(value) == "string" and value ~= "", label .. " contains an empty value")
        check(not seen[value], label .. " contains duplicate: " .. value)
        seen[value] = true
    end
end

return function(check)
    unique(check, data.bloodlines, "name", "Bloodline display names")
    unique(check, data.bloodlines, "id", "Bloodline internal IDs")
    unique(check, data.kenjutsu, "name", "Kenjutsu display names")
    unique(check, data.kenjutsu, "id", "Kenjutsu internal IDs")
end
