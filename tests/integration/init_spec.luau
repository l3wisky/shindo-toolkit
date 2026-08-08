local startToolkit = require("../../src")

return function(check)
    local runtimeGlobals = getfenv(startToolkit)
    local previousGame = runtimeGlobals.game
    local previousTask = runtimeGlobals.task

    local succeeded, reason = xpcall(function()
        local environment = {}
        local windows = {}
        local failBuild = false
        local fakeGame = {
            JobId = "integration-job",
        }
        function fakeGame:IsLoaded()
            return true
        end
        function fakeGame:GetService(name)
            check(name == "Players", "init should request the Players service")
            return {
                LocalPlayer = {},
            }
        end

        runtimeGlobals.game = fakeGame
        runtimeGlobals.task = {
            wait = function() end,
            defer = function(callback)
                callback()
            end,
        }

        local function createWindow()
            local window = {
                unloaded = false,
                unloadCalls = 0,
            }
            function window:Unload()
                self.unloadCalls += 1
                self.unloaded = true
            end
            function window:CreateTag() end
            function window:Toast() end
            function window:Notify() end
            table.insert(windows, window)
            return window
        end

        local rayfield = {}
        function rayfield:CreateWindow()
            return createWindow()
        end

        local config = {
            version = "test",
            rayfield = {},
            themes = {
                { id = "default" },
            },
            icons = {},
        }
        local i18n = {
            translate = function(_, key)
                return key
            end,
            rayfieldTranslations = function()
                return {}
            end,
        }
        local modules = {
            ["src/config.luau"] = config,
            ["src/data.luau"] = {},
            ["src/i18n.luau"] = i18n,
            ["src/platform.luau"] = function()
                return {
                    environment = function()
                        return environment
                    end,
                }
            end,
            ["src/storage.luau"] = function(app)
                app.storage = {
                    state = {
                        language = "en",
                        theme = "default",
                        notifications = true,
                    },
                    save = function()
                        return true
                    end,
                }
            end,
            ["src/value_state.luau"] = function()
                return {}
            end,
            ["src/runtime/rayfield.luau"] = function()
                return rayfield
            end,
            ["vendor/rayfield-gen2/bundled.luau"] = {},
            ["src/game/client.luau"] = function()
                return {}
            end,
            ["src/features/kg_changer.luau"] = function()
                if failBuild then
                    error("feature build failed")
                end
            end,
            ["src/features/rcgenkai.luau"] = function() end,
            ["src/features/misc/init.luau"] = function() end,
            ["src/features/misc/outfit.luau"] = function() end,
            ["src/features/misc/teleport.luau"] = function() end,
            ["src/features/misc/date.luau"] = function() end,
            ["src/features/misc/date_controller.luau"] = function() end,
            ["src/features/misc/player_info.luau"] = function() end,
            ["src/features/misc/settings.luau"] = function() end,
        }
        local bootstrap = {
            development = true,
            load = function(path)
                local loaded = modules[path]
                assert(loaded ~= nil, "missing fake module: " .. path)
                return loaded
            end,
        }

        local firstApp = startToolkit(bootstrap)
        local firstWindow = firstApp.window
        local firstDisconnects = 0
        firstApp.trackTemporary({
            Connected = true,
            Disconnect = function(connection)
                firstDisconnects += 1
                connection.Connected = false
            end,
        })

        local secondApp = startToolkit(bootstrap)
        check(
            firstWindow.unloadCalls == 1,
            "a repeated launch should unload the previous window exactly once"
        )
        check(firstDisconnects == 1, "a repeated launch should disconnect previous temporary connections")
        check(
            environment.__ShindoToolkitSession.app == secondApp,
            "the repeated launch should publish only the new app"
        )

        local secondWindow = secondApp.window
        local rebuildDisconnects = 0
        secondApp.trackTemporary({
            Connected = true,
            Disconnect = function(connection)
                rebuildDisconnects += 1
                connection.Connected = false
            end,
        })
        secondApp.rebuild()
        check(secondWindow.unloadCalls == 1, "rebuild should unload the old window exactly once")
        check(rebuildDisconnects == 1, "rebuild should disconnect temporary connections")
        check(
            environment.__ShindoToolkitSession.app == secondApp,
            "rebuild should republish its app only after success"
        )

        local rebuiltWindow = secondApp.window
        failBuild = true
        local built, buildError = pcall(startToolkit, bootstrap)
        check(not built, "a feature construction error should fail startup")
        check(
            string.find(tostring(buildError), "feature build failed", 1, true) ~= nil,
            "startup failure should retain its cause"
        )
        check(rebuiltWindow.unloadCalls == 1, "failed replacement should destroy the previously active app")
        check(windows[#windows].unloadCalls == 1, "failed startup should unload its partially created window")
        check(environment.__ShindoToolkitSession.app == nil, "failed startup must not publish a partial app")

        failBuild = false
        local recoveredApp = startToolkit(bootstrap)
        local activeWindows = 0
        for _, window in ipairs(windows) do
            if not window.unloaded then
                activeWindows += 1
            end
        end
        check(activeWindows == 1, "recovery should leave exactly one active window")
        check(
            environment.__ShindoToolkitSession.app == recoveredApp,
            "recovery should publish the complete app"
        )
    end, function(message)
        if type(debug) == "table" and type(debug.traceback) == "function" then
            return debug.traceback(tostring(message), 2)
        end
        return tostring(message)
    end)

    runtimeGlobals.game = previousGame
    runtimeGlobals.task = previousTask
    if not succeeded then
        error(reason, 0)
    end
end
