local i18n = require("../../src/i18n")

local function keys(source)
    local result = {}
    for key in pairs(source) do
        result[key] = true
    end
    return result
end

local function placeholders(source)
    local result = {}
    for name in string.gmatch(source, "{([%w_]+)}") do
        result[name] = true
    end
    return result
end

return function(check)
    local english, russian = keys(i18n.locales.en), keys(i18n.locales.ru)
    for key in pairs(english) do
        check(russian[key], "Russian locale is missing key: " .. key)
    end
    for key in pairs(russian) do
        check(english[key], "English locale is missing key: " .. key)
    end

    for key, englishSource in pairs(i18n.locales.en) do
        local englishPlaceholders = placeholders(englishSource)
        local russianPlaceholders = placeholders(i18n.locales.ru[key])
        for name in pairs(englishPlaceholders) do
            check(russianPlaceholders[name], string.format("Russian locale key %s is missing {%s}", key, name))
        end
        for name in pairs(russianPlaceholders) do
            check(
                englishPlaceholders[name],
                string.format("Russian locale key %s has unexpected {%s}", key, name)
            )
        end
    end

    local sources = {}
    for key, source in pairs(i18n.locales.en) do
        local firstKey = sources[source]
        if firstKey then
            check(
                i18n.locales.ru[firstKey] == i18n.locales.ru[key],
                string.format("Rayfield translation collision for %q: %s and %s", source, firstKey, key)
            )
        else
            sources[source] = key
        end
    end

    check(
        i18n.translate("en", "applied", { value = false }) == "Applied: false",
        "false placeholders must be retained"
    )
end
