return function(bootstrap)
    assert(type(bootstrap) == "table", "Shindo Toolkit bootstrap must be a table")
    assert(type(bootstrap.load) == "function", "Shindo Toolkit bootstrap.load must be a function")

    if not game:IsLoaded() then
        game.Loaded:Wait()
    end

    local Players = game:GetService("Players")
    while not Players.LocalPlayer do
        task.wait()
    end

    local config = bootstrap.load("src/config.luau")
    local data = bootstrap.load("src/data.luau")
    local i18n = bootstrap.load("src/i18n.luau")
    local createPlatform = bootstrap.load("src/platform.luau")
    local configureStorage = bootstrap.load("src/storage.luau")
    local createValueState = bootstrap.load("src/value_state.luau")
    local createDiagnostics = bootstrap.load("src/diagnostics.luau")
    local createKgChanger = bootstrap.load("src/kg_changer.luau")
    local createRcgenkai = bootstrap.load("src/rcgenkai.luau")
    local createMisc = bootstrap.load("src/misc.luau")

    local development = bootstrap.development == true
    local platform = createPlatform(development)
    local environment = platform.environment()
    local session = environment.__ShindoToolkitSession
    if type(session) ~= "table" or session.jobId ~= game.JobId or type(session.originals) ~= "table" then
        session = {
            jobId = game.JobId,
            originals = {},
        }
        environment.__ShindoToolkitSession = session
    end

    local rayfieldSource, downloadError = platform.httpGet(config.rayfield.url)
    if not rayfieldSource then
        error(
            string.format(
                "Rayfield Gen2 %s download failed: %s",
                config.rayfield.version,
                tostring(downloadError)
            ),
            0
        )
    end
    local rayfieldChunk, compileError =
        platform.compile(rayfieldSource, "ShindoToolkit/RayfieldGen2@" .. config.rayfield.version)
    if not rayfieldChunk then
        error(
            string.format(
                "Rayfield Gen2 %s compile failed: %s",
                config.rayfield.version,
                tostring(compileError)
            ),
            0
        )
    end
    local rayfieldLoaded, rayfield = pcall(rayfieldChunk)
    if not rayfieldLoaded then
        error(
            string.format("Rayfield Gen2 %s startup failed: %s", config.rayfield.version, tostring(rayfield)),
            0
        )
    end
    if type(rayfield) ~= "table" or type(rayfield.CreateWindow) ~= "function" then
        error("Rayfield Gen2 returned an invalid runtime", 0)
    end

    local themeIds = {}
    for _, theme in ipairs(config.themes) do
        themeIds[theme.id] = true
    end

    local app = {
        version = config.version,
        development = development,
        config = config,
        data = data,
        platform = platform,
        originals = session.originals,
        themes = config.themes,
        themeIds = themeIds,
        icons = config.icons,
        rayfield = rayfield,
    }
    configureStorage(app)
    app.settings = app.storage.state
    app.values = createValueState(app)
    app.diagnostics = createDiagnostics(app)
    app.ui = function(key)
        return i18n.translate("en", key)
    end
    app.t = function(key, values)
        return i18n.translate(app.settings.language, key, values)
    end
    app.save = function()
        return app.storage.save()
    end

    local temporaryConnections = {}
    app.trackTemporary = function(connection)
        if connection then
            table.insert(temporaryConnections, connection)
        end
        return connection
    end
    app.disconnectTemporary = function()
        for _, connection in ipairs(temporaryConnections) do
            pcall(function()
                if connection.Connected then
                    connection:Disconnect()
                end
            end)
        end
        table.clear(temporaryConnections)
    end

    local function unloadWindow()
        app.disconnectTemporary()
        local window = app.window
        app.window = nil
        if window and window.unloaded ~= true then
            pcall(function()
                window:Unload()
            end)
        end
    end

    local previousApp = session.app

    local function build()
        app.window = app.rayfield:CreateWindow({
            name = "shindo toolkit",
            showName = "shindo toolkit",
            theme = app.settings.theme,
            locale = app.settings.language,
            translations = i18n.rayfieldTranslations(),
        })

        app.toast = function(contentKey, values)
            if app.settings.notifications and app.window and app.window.unloaded == false then
                app.window:Toast({
                    title = app.t(contentKey, values),
                    duration = 3,
                })
            end
        end
        app.error = function(contentKey, values)
            if app.window and app.window.unloaded == false then
                app.window:Notify({
                    title = app.t("error"),
                    content = app.t(contentKey, values),
                    duration = 4,
                })
            end
        end

        app.window:CreateTag({
            text = "v" .. app.version,
            order = 1,
        })
        if app.development then
            app.window:CreateTag({
                text = "DEV",
                order = 2,
            })
        end

        createKgChanger(app)
        createRcgenkai(app)
        createMisc(app)
    end

    local function buildSafely()
        local succeeded, reason = xpcall(build, function(message)
            if type(debug) == "table" and type(debug.traceback) == "function" then
                return debug.traceback(tostring(message), 2)
            end
            return tostring(message)
        end)
        if not succeeded then
            unloadWindow()
            error("Shindo Toolkit UI startup failed:\n" .. tostring(reason), 0)
        end
    end

    app.rebuild = function()
        session.app = nil
        unloadWindow()
        buildSafely()
        session.app = app
    end
    app.destroy = function()
        if session.app == app then
            session.app = nil
        end
        unloadWindow()
    end

    buildSafely()

    -- Keep an existing session alive until the replacement UI has been built.
    -- Failed downloads, compilation, and initial UI construction therefore do
    -- not turn a harmless reload into a destructive one.
    if previousApp then
        local destroyed = false
        if type(previousApp.destroy) == "function" then
            destroyed = pcall(previousApp.destroy)
        end
        if not destroyed then
            if type(previousApp.disconnectTemporary) == "function" then
                pcall(previousApp.disconnectTemporary)
            end
            local previousWindow = previousApp.window
            if previousWindow and previousWindow.unloaded ~= true then
                pcall(function()
                    previousWindow:Unload()
                end)
            end
        end
    end
    session.app = app
    return app
end
