return function(bootstrap)
    if not game:IsLoaded() then
        game.Loaded:Wait()
    end

    local Players = game:GetService("Players")
    while not Players.LocalPlayer do
        task.wait()
    end

    local data = bootstrap.load("src/data.luau")
    local i18n = bootstrap.load("src/i18n.luau")
    local configureStorage = bootstrap.load("src/storage.luau")
    local createKgChanger = bootstrap.load("src/kg_changer.luau")
    local createRcgenkai = bootstrap.load("src/rcgenkai.luau")
    local createMisc = bootstrap.load("src/misc.luau")

    local environment = if getgenv then getgenv() else _G
    local session = environment.__ShindoToolkitSession
    if type(session) ~= "table" or session.jobId ~= game.JobId then
        session = {
            jobId = game.JobId,
            originals = {},
        }
        environment.__ShindoToolkitSession = session
    end

    local previousApp = session.app
    if previousApp then
        if previousApp.disconnectTemporary then
            previousApp.disconnectTemporary()
        end
        local previousWindow = previousApp.window
        if previousWindow and previousWindow.unloaded == false then
            previousWindow:Unload()
        end
    end
    session.app = nil

    local themes = {
        { id = "default", labelKey = "theme_default" },
        { id = "cobalt", labelKey = "theme_cobalt" },
        { id = "ember", labelKey = "theme_ember" },
        { id = "amethyst", labelKey = "theme_amethyst" },
        { id = "frost", labelKey = "theme_frost" },
        { id = "rose", labelKey = "theme_rose" },
    }
    local themeIds = {}
    for _, theme in ipairs(themes) do
        themeIds[theme.id] = true
    end

    local app = {
        development = bootstrap.development,
        runtimeRef = bootstrap.runtimeRef,
        data = data,
        originals = session.originals,
        themes = themes,
        themeIds = themeIds,
        icons = {
            kg = 84750991656135,
            rcgenkai = 125823673784681,
            misc = 93364949241311,
            github = 85925158736685,
        },
    }
    configureStorage(app)
    app.settings = app.storage.state
    app.ui = function(key)
        return i18n.translate("en", key)
    end
    app.t = function(key, values)
        return i18n.translate(app.settings.language, key, values)
    end
    app.save = function()
        return app.storage.save()
    end

    local rayfieldUrl = "https://github.com/SiriusSoftwareLtd/rayfield-gen2/releases/download/1.1.0/bundled.luau"
    local downloaded, rayfieldSource = pcall(function()
        return game:HttpGet(rayfieldUrl)
    end)
    if not downloaded then
        error("Rayfield Gen2 1.1.0 download failed: " .. tostring(rayfieldSource))
    end

    local rayfieldChunk, compileError = loadstring(rayfieldSource, "ShindoToolkit/RayfieldGen2@1.1.0")
    if not rayfieldChunk then
        error("Rayfield Gen2 1.1.0 compile failed: " .. tostring(compileError))
    end
    app.rayfield = rayfieldChunk()

    local temporaryConnections = {}
    app.trackTemporary = function(connection)
        table.insert(temporaryConnections, connection)
        return connection
    end
    app.disconnectTemporary = function()
        for _, connection in ipairs(temporaryConnections) do
            if connection.Connected then
                connection:Disconnect()
            end
        end
        table.clear(temporaryConnections)
    end

    local function build()
        app.window = app.rayfield:CreateWindow({
            name = "shindo toolkit",
            showName = "shindo toolkit",
            theme = app.settings.theme,
            locale = app.settings.language,
            translations = i18n.rayfieldTranslations(),
            configuration = {
                autoSave = false,
                autoLoad = false,
            },
        })

        app.toast = function(contentKey, values)
            if app.settings.notifications then
                app.window:Toast({
                    title = app.t(contentKey, values),
                    duration = 3,
                })
            end
        end
        app.error = function(contentKey, values)
            app.window:Notify({
                title = app.t("error"),
                content = app.t(contentKey, values),
                duration = 4,
            })
        end
        if app.development then
            app.window:CreateTag({
                text = "DEV",
            })
        end

        createKgChanger(app)
        createRcgenkai(app)
        createMisc(app)
    end

    app.rebuild = function()
        app.disconnectTemporary()
        if app.window and app.window.unloaded == false then
            app.window:Unload()
        end
        build()
    end

    build()
    session.app = app
    return app
end
