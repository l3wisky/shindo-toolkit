return function(app)
    local HttpService = game:GetService("HttpService")
    local folder = "ShindoToolkit"
    local path = "ShindoToolkit/settings.v1.json"
    local defaults = {
        version = 1,
        language = "en",
        theme = "default",
        notifications = true,
        presets = {},
    }

    local knownBloodlines = {}
    for _, bloodline in ipairs(app.data.bloodlines) do
        knownBloodlines[bloodline.name] = true
    end

    local function applyDefaults(state)
        table.clear(state)
        for key, value in pairs(defaults) do
            state[key] = if type(value) == "table" then {} else value
        end
    end

    local function normalizePresets(presets)
        local normalized = {}
        if type(presets) ~= "table" then
            return normalized
        end

        local seen = {}
        for _, name in ipairs(presets) do
            if type(name) == "string" and knownBloodlines[name] and not seen[name] then
                seen[name] = true
                table.insert(normalized, name)
            end
        end
        table.sort(normalized)
        return normalized
    end

    local state = {}
    applyDefaults(state)

    if type(isfile) == "function" and type(readfile) == "function" and isfile(path) then
        local readSucceeded, contents = pcall(readfile, path)
        if readSucceeded then
            local decodeSucceeded, decoded = pcall(function()
                return HttpService:JSONDecode(contents)
            end)
            if decodeSucceeded and type(decoded) == "table" and decoded.version == 1 then
                state.language = if decoded.language == "ru" then "ru" else "en"
                state.theme = if app.themeIds[decoded.theme] then decoded.theme else defaults.theme
                state.notifications = decoded.notifications ~= false
                state.presets = normalizePresets(decoded.presets)
            end
        end
    end

    local storage = {
        state = state,
    }

    function storage.save()
        if type(writefile) ~= "function" then
            return false
        end

        local succeeded = pcall(function()
            if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder(folder) then
                makefolder(folder)
            end
            writefile(path, HttpService:JSONEncode(state))
        end)
        return succeeded
    end

    function storage.reset()
        applyDefaults(state)
        if type(isfile) ~= "function" or not isfile(path) then
            return true
        end

        if type(delfile) == "function" then
            pcall(delfile, path)
            if not isfile(path) then
                return true
            end
        end
        return storage.save()
    end

    app.storage = storage
end
