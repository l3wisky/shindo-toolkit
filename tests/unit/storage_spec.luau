local configureStorage = require("../../src/storage")

local function codec(decoded, decodeFailure, encodeFailure)
    local result = {}

    function result:JSONDecode(_)
        if decodeFailure then
            error(decodeFailure)
        end
        return decoded
    end

    function result:JSONEncode(state)
        if encodeFailure then
            error(encodeFailure)
        end
        return string.format(
            "%d|%s|%s|%s",
            state.version,
            state.language,
            state.theme,
            tostring(state.notifications)
        )
    end

    return result
end

local function createApp(options)
    options = options or {}
    local writes = {}
    local app = {
        themeIds = {
            default = true,
            cobalt = true,
        },
        platform = {
            storageFolder = "ShindoToolkit",
            capabilities = {
                filesystem = options.filesystem == true,
            },
            readText = function()
                return options.contents
            end,
            writeText = function(path, contents)
                table.insert(writes, { path = path, contents = contents })
                if options.writeFailure then
                    return false, options.writeFailure
                end
                return true, nil
            end,
            deleteFile = function()
                if options.deleteFailure then
                    return false, options.deleteFailure
                end
                return true, nil
            end,
        },
    }
    return app, writes
end

return function(check)
    local corruptApp = createApp({ contents = "not-json" })
    configureStorage(corruptApp, codec(nil, "decode failed"))
    check(corruptApp.storage.state.language == "en", "corrupt settings should use the default language")
    check(corruptApp.storage.state.theme == "default", "corrupt settings should use the default theme")
    check(corruptApp.storage.state.notifications == true, "corrupt settings should use default notifications")

    local oldApp = createApp({ contents = "old" })
    configureStorage(
        oldApp,
        codec({
            version = 0,
            language = "ru",
            theme = "cobalt",
            notifications = false,
        })
    )
    check(oldApp.storage.state.language == "en", "unknown settings versions should be ignored")
    check(oldApp.storage.state.theme == "default", "unknown settings versions should not leak values")

    local validApp = createApp({ contents = "valid", filesystem = true })
    configureStorage(
        validApp,
        codec({
            version = 1,
            language = "ru",
            theme = "cobalt",
            notifications = false,
        })
    )
    check(validApp.storage.persistent == true, "filesystem capability should be exposed")
    check(validApp.storage.state.language == "ru", "valid language should load")
    check(validApp.storage.state.theme == "cobalt", "valid theme should load")
    check(validApp.storage.state.notifications == false, "false notifications should be preserved")

    local invalidFieldsApp = createApp({ contents = "valid" })
    configureStorage(
        invalidFieldsApp,
        codec({
            version = 1,
            language = "unknown",
            theme = "missing",
            notifications = "yes",
        })
    )
    check(invalidFieldsApp.storage.state.language == "en", "unknown language should be sanitized")
    check(invalidFieldsApp.storage.state.theme == "default", "unknown theme should be sanitized")
    check(invalidFieldsApp.storage.state.notifications == true, "invalid notifications should be sanitized")

    local failingApp = createApp({ writeFailure = "disk full" })
    configureStorage(failingApp, codec(nil))
    check(not failingApp.storage.save(), "write failures should fail save")
    check(failingApp.storage.lastError == "disk full", "write failure should be retained")

    local resetApp, writes = createApp({ deleteFailure = "delete unsupported" })
    configureStorage(resetApp, codec(nil))
    resetApp.storage.state.language = "ru"
    check(resetApp.storage.reset(), "reset should fall back to writing defaults")
    check(resetApp.storage.state.language == "en", "reset should restore defaults in memory")
    check(#writes == 1, "reset fallback should write exactly once")
    check(
        writes[1].path == "ShindoToolkit/settings.v1.json",
        "settings should use the versioned storage path"
    )

    local encodingApp = createApp()
    configureStorage(encodingApp, codec(nil, nil, "encode failed"))
    check(not encodingApp.storage.save(), "encoding failures should fail save")
    check(
        encodingApp.storage.lastError:match("^settings encoding failed:") ~= nil,
        "encoding failure should be explained"
    )
end
