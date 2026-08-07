return function(app)
    local HttpService = game:GetService("HttpService")
    local path = app.platform.storageFolder .. "/settings.v1.json"
    local defaults = {
        version = 1,
        language = "en",
        theme = "default",
        notifications = true,
    }

    local function applyDefaults(state)
        table.clear(state)
        for key, value in pairs(defaults) do
            state[key] = value
        end
    end

    local state = {}
    applyDefaults(state)

    local contents = app.platform.readText(path)
    if contents then
        local decodedSuccessfully, decoded = pcall(function()
            return HttpService:JSONDecode(contents)
        end)
        if decodedSuccessfully and type(decoded) == "table" and decoded.version == defaults.version then
            state.language = if decoded.language == "ru" then "ru" else defaults.language
            state.theme = if app.themeIds[decoded.theme] then decoded.theme else defaults.theme
            state.notifications = if type(decoded.notifications) == "boolean"
                then decoded.notifications
                else defaults.notifications
        end
    end

    local storage = {
        state = state,
        path = path,
        persistent = app.platform.capabilities.filesystem,
        lastError = nil,
    }

    function storage.save()
        local encodedSuccessfully, encoded = pcall(function()
            return HttpService:JSONEncode(state)
        end)
        if not encodedSuccessfully then
            storage.lastError = "settings encoding failed: " .. tostring(encoded)
            return false
        end

        local saved, reason = app.platform.writeText(path, encoded)
        storage.lastError = if saved then nil else tostring(reason)
        return saved
    end

    function storage.reset()
        applyDefaults(state)

        local deleted, reason = app.platform.deleteFile(path)
        if deleted then
            storage.lastError = nil
            return true
        end

        -- Some executors support writing files but not deleting them. Persisting
        -- the defaults is equivalent and keeps reset useful in that environment.
        local saved = storage.save()
        if not saved and storage.lastError == nil then
            storage.lastError = tostring(reason)
        end
        return saved
    end

    app.storage = storage
end
