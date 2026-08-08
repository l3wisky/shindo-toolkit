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
    local createRayfield = bootstrap.load("src/runtime/rayfield.luau")
    local createGameClient = bootstrap.load("src/game/client.luau")
    local createKgChanger = bootstrap.load("src/features/kg_changer.luau")
    local createRcgenkai = bootstrap.load("src/features/rcgenkai.luau")
    local createMisc = bootstrap.load("src/features/misc/init.luau")
    local miscModules = {
        outfit = bootstrap.load("src/features/misc/outfit.luau"),
        teleport = bootstrap.load("src/features/misc/teleport.luau"),
        date = bootstrap.load("src/features/misc/date.luau"),
        createDateController = bootstrap.load("src/features/misc/date_controller.luau"),
        playerInfo = bootstrap.load("src/features/misc/player_info.luau"),
        settings = bootstrap.load("src/features/misc/settings.luau"),
    }

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

    local rayfield = createRayfield(platform, config.rayfield)

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
    app.ui = function(key)
        return i18n.translate("en", key)
    end
    app.t = function(key, values)
        return i18n.translate(app.settings.language, key, values)
    end
    app.save = function()
        return app.storage.save()
    end
    app.missing = function(key, path)
        local values = { path = path }
        app.error(key, values)
        if app.development then
            local message = app.t(key, values)
            task.defer(function()
                error(message, 0)
            end)
        end
        return false
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
    app.game = createGameClient(app)

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
        createMisc(app, miscModules)
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

    session.app = nil
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

    buildSafely()
    session.app = app
    return app
end
