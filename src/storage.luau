return function(app)
    local HttpService = game:GetService("HttpService")
    local folder, path = "ShindoToolkit", "ShindoToolkit/settings.v1.json"
    local defaults = { version = 1, language = "en", theme = "default", notifications = true, presets = {}, outfit_slot = 1 }
    local knownBloodlines = {}
    for _, item in ipairs(app.data.bloodlines) do knownBloodlines[item.name] = true end

    local function applyDefaults(state)
        table.clear(state)
        for key, value in pairs(defaults) do state[key] = type(value) == "table" and {} or value end
    end
    local state = {}
    applyDefaults(state)

    if isfile and readfile and isfile(path) then
        local okRead, contents = pcall(readfile, path)
        if okRead then
            local okDecode, decoded = pcall(function() return HttpService:JSONDecode(contents) end)
            if okDecode and type(decoded) == "table" and decoded.version == 1 then
                state.language = decoded.language == "ru" and "ru" or "en"
                state.theme = app.themeIds[decoded.theme] and decoded.theme or defaults.theme
                state.notifications = decoded.notifications ~= false
                state.outfit_slot = math.clamp(math.floor(tonumber(decoded.outfit_slot) or 1), 1, 9)
                if type(decoded.presets) == "table" then
                    local seen = {}
                    for _, name in ipairs(decoded.presets) do
                        if type(name) == "string" and knownBloodlines[name] and not seen[name] then
                            seen[name] = true
                            table.insert(state.presets, name)
                        end
                    end
                    table.sort(state.presets)
                end
            end
        end
    end

    local storage = { state = state }
    function storage.save()
        if not writefile then return false end
        local ok = pcall(function()
            if isfolder and makefolder and not isfolder(folder) then makefolder(folder) end
            writefile(path, HttpService:JSONEncode(state))
        end)
        return ok
    end
    function storage.reset()
        applyDefaults(state)
        if not isfile then return true end
        if not isfile(path) then return true end
        if delfile then
            pcall(delfile, path)
            if not isfile(path) then return true end
        end
        return storage.save()
    end
    app.storage = storage
end
