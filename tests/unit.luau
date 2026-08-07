local config = require("../src/config")
local data = require("../src/data")
local i18n = require("../src/i18n")
local createValueState = require("../src/value_state")

local checks = 0
local function check(condition, message)
    checks += 1
    assert(condition, message)
end

local function keys(source)
    local result = {}
    for key in pairs(source) do
        result[key] = true
    end
    return result
end

local english, russian = keys(i18n.locales.en), keys(i18n.locales.ru)
for key in pairs(english) do
    check(russian[key], "Russian locale is missing key: " .. key)
end
for key in pairs(russian) do
    check(english[key], "English locale is missing key: " .. key)
end

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

local function unique(items, field, label)
    local seen = {}
    for _, item in ipairs(items) do
        local value = item[field]
        check(type(value) == "string" and value ~= "", label .. " contains an empty value")
        check(not seen[value], label .. " contains duplicate: " .. value)
        seen[value] = true
    end
end

unique(data.bloodlines, "name", "Bloodline display names")
unique(data.bloodlines, "id", "Bloodline internal IDs")
unique(data.kenjutsu, "name", "Kenjutsu display names")
unique(data.kenjutsu, "id", "Kenjutsu internal IDs")

check(config.version:match("^%d+%.%d+%.%d+$") ~= nil, "version must use SemVer core format")
check(
    config.releaseArtifactUrl:match("/releases/latest/download/shindo%-toolkit%.luau$") ~= nil,
    "invalid artifact URL"
)
check(
    #config.rayfield.sha256 == 64 and config.rayfield.sha256:match("^%x+$") ~= nil,
    "Rayfield SHA-256 must contain 64 hexadecimal characters"
)
for _, theme in ipairs(config.themes) do
    check(
        i18n.locales.en[theme.labelKey] ~= nil,
        "theme is missing an English translation: " .. theme.labelKey
    )
    check(
        i18n.locales.ru[theme.labelKey] ~= nil,
        "theme is missing a Russian translation: " .. theme.labelKey
    )
end
check(
    i18n.translate("en", "applied", { value = false }) == "Applied: false",
    "false placeholders must be retained"
)

local function node(value, children)
    return {
        Value = value,
        children = children or {},
        FindFirstChild = function(self, name)
            return self.children[name]
        end,
    }
end

local messages = {}
local app = {
    originals = {},
    error = function(key)
        table.insert(messages, "error:" .. key)
    end,
    toast = function(key)
        table.insert(messages, "toast:" .. key)
    end,
    missing = function(key, path)
        table.insert(messages, "missing:" .. key .. ":" .. path)
        return false
    end,
}
local target = node("original")
local root = node(nil, { nested = node(nil, { target = target }) })
local values = createValueState(app)

check(values.apply(root, { "nested", "target" }, "sample", "first", "First"), "apply should succeed")
check(target.Value == "first", "apply should write the selected value")
check(app.originals.sample == "original", "apply should capture the original once")
check(values.apply(root, { "nested", "target" }, "sample", "second", "Second"), "second apply should succeed")
check(app.originals.sample == "original", "second apply must not replace the original")
check(values.restore(root, { "nested", "target" }, "sample"), "restore should succeed")
check(target.Value == "original", "restore should write the captured original")
check(
    not values.apply(root, { "missing" }, "missing", "value", "Value", "Root.missing"),
    "missing target should fail"
)
check(
    messages[#messages] == "missing:target_missing:Root.missing",
    "missing target should report its exact path"
)

print(string.format("unit: %d checks passed", checks))
