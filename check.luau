-- Run manually with: luau check.luau
local data = require("./src/data")
local i18n = require("./src/i18n")

local function keys(source)
    local result = {}
    for key in pairs(source) do result[key] = true end
    return result
end

local english, russian = keys(i18n.locales.en), keys(i18n.locales.ru)
for key in pairs(english) do assert(russian[key], "Russian locale is missing key: " .. key) end
for key in pairs(russian) do assert(english[key], "English locale is missing key: " .. key) end

local function unique(items, field, label)
    local seen = {}
    for _, item in ipairs(items) do
        local value = item[field]
        assert(type(value) == "string" and value ~= "", label .. " contains an empty value")
        assert(not seen[value], label .. " contains duplicate: " .. value)
        seen[value] = true
    end
end

unique(data.bloodlines, "name", "Bloodline display names")
unique(data.bloodlines, "id", "Bloodline internal IDs")
unique(data.kenjutsu, "name", "Kenjutsu display names")
unique(data.kenjutsu, "id", "Kenjutsu internal IDs")
print("check.luau: all checks passed")
