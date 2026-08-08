local config = require("../../src/config")
local i18n = require("../../src/i18n")

return function(check)
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
end
