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

local function placeholders(source)
    local result = {}
    for name in string.gmatch(source, "{([%w_]+)}") do
        result[name] = true
    end
    return result
end

for key, englishSource in pairs(i18n.locales.en) do
    local englishPlaceholders = placeholders(englishSource)
    local russianPlaceholders = placeholders(i18n.locales.ru[key])
    for name in pairs(englishPlaceholders) do
        assert(russianPlaceholders[name], string.format("Russian locale key %s is missing placeholder {%s}", key, name))
    end
    for name in pairs(russianPlaceholders) do
        assert(englishPlaceholders[name], string.format("Russian locale key %s has unexpected placeholder {%s}", key, name))
    end
end

local sources = {}
for key, source in pairs(i18n.locales.en) do
    local firstKey = sources[source]
    if firstKey then
        local firstRussian = i18n.locales.ru[firstKey]
        local conflictingRussian = i18n.locales.ru[key]
        assert(
            firstRussian == conflictingRussian,
            string.format(
                "Rayfield translation collision for %q: %s=%q conflicts with %s=%q",
                source,
                firstKey,
                firstRussian,
                key,
                conflictingRussian
            )
        )
    else
        sources[source] = key
    end
end

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
