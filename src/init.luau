return function(bootstrap)
    if not game:IsLoaded() then game.Loaded:Wait() end
    local Players = game:GetService("Players")
    while not Players.LocalPlayer do task.wait() end

    local data = bootstrap.load("src/data.luau")
    local i18n = bootstrap.load("src/i18n.luau")
    local configureStorage = bootstrap.load("src/storage.luau")
    local createKgChanger = bootstrap.load("src/kg_changer.luau")
    local createRcgenkai = bootstrap.load("src/rcgenkai.luau")
    local createMisc = bootstrap.load("src/misc.luau")

    local environment = getgenv and getgenv() or _G
    local session = environment.__ShindoToolkitSession
    if type(session) ~= "table" or session.jobId ~= game.JobId then
        session = { jobId = game.JobId, originals = {} }
        environment.__ShindoToolkitSession = session
    elseif session.app then
        if session.app.disconnectTemporary then session.app.disconnectTemporary() end
        if session.app.window and not session.app.window.unloaded then session.app.window:Unload() end
    end

    local themes = {
        { id = "default", labelKey = "theme_default" }, { id = "cobalt", labelKey = "theme_cobalt" },
        { id = "ember", labelKey = "theme_ember" }, { id = "amethyst", labelKey = "theme_amethyst" },
        { id = "frost", labelKey = "theme_frost" }, { id = "rose", labelKey = "theme_rose" },
    }
    local themeIds = {}
    for _, theme in ipairs(themes) do themeIds[theme.id] = true end

    local app = { branch = bootstrap.branch, data = data, originals = session.originals, themes = themes, themeIds = themeIds }
    configureStorage(app)
    app.settings = app.storage.state
    app.t = function(key, values) return i18n.translate(app.settings.language, key, values) end
    app.save = function()
        local saved = app.storage.save()
        if not saved and app.window then app.notify("error", "filesystem_unavailable") end
        return saved
    end

    local artifactUrl = "https://github.com/SiriusSoftwareLtd/rayfield-gen2/releases/download/1.1.0/bundled.luau"
    local okDownload, source = pcall(function() return game:HttpGet(artifactUrl) end)
    if not okDownload then error("Rayfield Gen2 download failed: " .. tostring(source)) end
    local chunk, compileError = loadstring(source, "ShindoToolkit/RayfieldGen2@1.1.0")
    if not chunk then error("Rayfield Gen2 compile failed: " .. tostring(compileError)) end
    app.rayfield = chunk()

    local temporaryConnections = {}
    app.trackTemporary = function(connection) table.insert(temporaryConnections, connection); return connection end
    app.disconnectTemporary = function()
        for _, connection in ipairs(temporaryConnections) do connection:Disconnect() end
        table.clear(temporaryConnections)
    end

    local rebuilding = false
    local function build()
        app.window = app.rayfield:CreateWindow({
            name = app.t("window_title"), subtitle = app.t("window_subtitle"), theme = app.settings.theme,
            showName = app.t("window_title"), locale = "en", configuration = { autoSave = false, autoLoad = false },
        })
        app.notify = function(titleKey, contentKey, values)
            if app.settings.notifications then
                app.window:Notify({ title = app.t(titleKey), content = app.t(contentKey, values), duration = 3.5 })
            end
        end
        createKgChanger(app)
        createRcgenkai(app)
        createMisc(app)
    end
    app.rebuild = function()
        if rebuilding then return end
        rebuilding = true
        app.disconnectTemporary()
        if app.window and not app.window.unloaded then app.window:Unload() end
        build()
        rebuilding = false
    end

    session.app = app
    build()
    return app
end
