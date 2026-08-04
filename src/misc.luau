return function(app)
    local Players = game:GetService("Players")
    local TeleportService = game:GetService("TeleportService")
    local localPlayer = Players.LocalPlayer
    local repositoryUrl = "https://github.com/l3wisky/shindo-toolkit"

    local tab = app.window:CreateTab({
        name = app.ui("tab_misc"),
    })
    local selectedPlayerName = localPlayer.Name
    local rejoinFailureConnection = nil

    local function fireRemote(command, value)
        local event = localPlayer:FindFirstChild("startevent")
        if not event or not event.FireServer then
            app.error("target_missing")
            return false
        end
        local succeeded, reason = pcall(function()
            event:FireServer(command, value)
        end)
        if not succeeded then
            app.error("request_failed", { reason = reason })
            return false
        end
        return true
    end

    local function disconnectRejoinFailure()
        if rejoinFailureConnection and rejoinFailureConnection.Connected then
            rejoinFailureConnection:Disconnect()
        end
        rejoinFailureConnection = nil
    end

    local function rejoin()
        disconnectRejoinFailure()
        rejoinFailureConnection = app.trackTemporary(TeleportService.TeleportInitFailed:Connect(function(failedPlayer, _, message)
            if failedPlayer ~= localPlayer then
                return
            end
            disconnectRejoinFailure()
            app.error("request_failed", { reason = message })
        end))

        local succeeded, reason = pcall(function()
            TeleportService:Teleport(game.PlaceId, localPlayer)
        end)
        if not succeeded then
            disconnectRejoinFailure()
            app.error("request_failed", { reason = reason })
            return false
        end
        app.toast("rejoining")
        return true
    end

    local function bandValue()
        local statz = localPlayer:FindFirstChild("statz")
        local character = statz and statz:FindFirstChild("character")
        return character and character:FindFirstChild("band")
    end

    local function rollback()
        local band = bandValue()
        if not band then
            app.error("target_missing")
            return false
        end
        if app.originals.date == nil then
            app.originals.date = band.Value
        end

        local rollbackValue = string.char(128)
        if not fireRemote("band", rollbackValue) then
            return false
        end

        local deadline = os.clock() + 4
        repeat
            if tostring(band.Value) == rollbackValue then
                app.toast("date_saved")
                return true
            end
            task.wait(0.08)
        until os.clock() >= deadline

        app.error("rollback_unconfirmed")
        return false
    end

    tab:CreateSection({
        name = app.ui("section_outfit"),
    })
    tab:CreateDropdown({
        name = app.ui("outfit_slot"),
        options = { "1", "2", "3", "4", "5", "6", "7", "8", "9" },
        value = tostring(app.settings.outfit_slot),
        forgetState = true,
        callback = function(value)
            app.settings.outfit_slot = tonumber(value) or 1
            if app.save() then
                app.toast("settings_saved")
            end
        end,
    })
    tab:CreateButton({
        name = app.ui("load_outfit"),
        callback = function()
            fireRemote("loadoutfit", app.settings.outfit_slot)
        end,
    })

    tab:CreateSection({
        name = app.ui("section_teleport"),
    })
    local teleportActions = tab:CreateGroup({
        direction = "row",
    })
    teleportActions:CreateButton({
        name = app.ui("home"),
        callback = function()
            fireRemote("arenateleport", 5451410109)
        end,
    })
    teleportActions:CreateButton({
        name = app.ui("rejoin"),
        callback = rejoin,
    })

    tab:CreateSection({
        name = app.ui("section_date"),
    })
    local dateActions = tab:CreateGroup({
        direction = "row",
    })
    dateActions:CreateButton({
        name = app.ui("rollback_date"),
        callback = rollback,
    })
    dateActions:CreateButton({
        name = app.ui("restore_date"),
        callback = function()
            if app.originals.date == nil then
                app.error("original_unavailable")
                return
            end
            if fireRemote("band", app.originals.date) then
                app.toast("restored", { value = app.originals.date })
            end
        end,
    })
    tab:CreateButton({
        name = app.ui("rollback_rejoin"),
        callback = function()
            app.window:Popup({
                title = app.ui("rollback_rejoin"),
                content = app.ui("rollback_confirm"),
                options = {
                    {
                        text = app.ui("cancel"),
                        style = "neutral",
                    },
                    {
                        text = app.ui("confirm"),
                        style = "primary",
                        callback = function()
                            if rollback() then
                                rejoin()
                            end
                        end,
                    },
                },
            })
        end,
    })

    tab:CreateSection({
        name = app.ui("section_player"),
    })

    local function playerNames(excludedPlayer)
        local names = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= excludedPlayer then
                table.insert(names, player.Name)
            end
        end
        table.sort(names)
        return names
    end

    local playersDropdown
    local function refreshPlayers(excludedPlayer)
        local names = playerNames(excludedPlayer)
        local selectedIsValid = table.find(names, selectedPlayerName) ~= nil
        if not selectedIsValid then
            if localPlayer ~= excludedPlayer and table.find(names, localPlayer.Name) then
                selectedPlayerName = localPlayer.Name
            else
                selectedPlayerName = names[1]
            end
        end
        playersDropdown:Refresh(names)
        if selectedPlayerName then
            playersDropdown:Set(selectedPlayerName, true)
        end
    end

    playersDropdown = tab:CreateDropdown({
        name = app.ui("player"),
        options = playerNames(),
        value = selectedPlayerName,
        forgetState = true,
        callback = function(name)
            if Players:FindFirstChild(name) then
                selectedPlayerName = name
            end
        end,
    })

    tab:CreateButton({
        name = app.ui("view_player"),
        callback = function()
            local target = selectedPlayerName and Players:FindFirstChild(selectedPlayerName)
            if not target then
                app.error("player_unavailable")
                return
            end

            local statz = target:FindFirstChild("statz")
            local ps = statz and statz:FindFirstChild("ps")
            local codeValue = ps and ps:FindFirstChild("mycode")
            local daysValue = statz and statz:FindFirstChild("gamedays")
            local code = codeValue and tostring(codeValue.Value) or ""
            local days = daysValue and tostring(daysValue.Value) or ""
            local resolvedCode = if code ~= "" then code else nil
            local resolvedDays = if days ~= "" then days else app.t("unavailable")

            local options = {
                {
                    text = app.ui("close"),
                    style = "neutral",
                },
            }
            if resolvedCode then
                table.insert(options, {
                    text = app.ui("copy_ps"),
                    style = "primary",
                    callback = function()
                        if type(setclipboard) ~= "function" then
                            app.error("clipboard_failed")
                            return
                        end
                        local copied = pcall(setclipboard, resolvedCode)
                        if copied then
                            app.toast("ps_copied")
                        else
                            app.error("clipboard_failed")
                        end
                    end,
                })
            end

            app.window:Popup({
                title = app.t("selected_player", { name = target.Name }),
                boxes = {
                    {
                        title = app.t("game_days_label"),
                        description = resolvedDays,
                    },
                    {
                        title = app.t("ps_code_label"),
                        description = resolvedCode or app.t("unavailable"),
                    },
                },
                options = options,
            })
        end,
    })

    app.trackTemporary(Players.PlayerAdded:Connect(function()
        refreshPlayers(nil)
    end))
    app.trackTemporary(Players.PlayerRemoving:Connect(function(removingPlayer)
        refreshPlayers(removingPlayer)
    end))

    tab:CreateSection({
        name = app.ui("section_settings"),
    })
    local languageIds = {
        [app.ui("english")] = "en",
        [app.ui("russian")] = "ru",
    }
    tab:CreateDropdown({
        name = app.ui("language"),
        options = { app.ui("english"), app.ui("russian") },
        value = if app.settings.language == "ru" then app.ui("russian") else app.ui("english"),
        forgetState = true,
        callback = function(choice)
            local language = languageIds[choice]
            if language and language ~= app.settings.language then
                app.settings.language = language
                app.save()
                app.window:SetLocale(language)
                app.toast("settings_saved")
            end
        end,
    })

    local themeLabels = {}
    local themeIdsByLabel = {}
    local selectedThemeLabel = nil
    for _, theme in ipairs(app.themes) do
        local label = app.ui(theme.labelKey)
        table.insert(themeLabels, label)
        themeIdsByLabel[label] = theme.id
        if theme.id == app.settings.theme then
            selectedThemeLabel = label
        end
    end
    tab:CreateDropdown({
        name = app.ui("theme"),
        options = themeLabels,
        value = selectedThemeLabel,
        forgetState = true,
        callback = function(label)
            local theme = themeIdsByLabel[label]
            if theme and theme ~= app.settings.theme then
                app.settings.theme = theme
                app.save()
                app.window:ChangeTheme(theme)
                app.toast("settings_saved")
            end
        end,
    })
    tab:CreateToggle({
        name = app.ui("notifications"),
        value = app.settings.notifications,
        forgetState = true,
        callback = function(value)
            app.settings.notifications = value
            app.save()
            app.toast("settings_saved")
        end,
    })
    tab:CreateButton({
        name = app.ui("reset_settings"),
        callback = function()
            app.window:Popup({
                title = app.ui("reset_settings"),
                content = app.ui("reset_confirm"),
                options = {
                    {
                        text = app.ui("cancel"),
                        style = "neutral",
                    },
                    {
                        text = app.ui("reset"),
                        style = "danger",
                        callback = function()
                            if not app.storage.reset() then
                                app.error("settings_reset_failed")
                                return
                            end
                            app.window:SetLocale(app.settings.language)
                            app.window:ChangeTheme(app.settings.theme)
                            app.toast("settings_reset")
                            task.defer(app.rebuild)
                        end,
                    },
                },
            })
        end,
    })
    tab:CreateButton({
        name = app.ui("github"),
        callback = function()
            if type(setclipboard) == "function" then
                local copied = pcall(setclipboard, repositoryUrl)
                if copied then
                    app.toast("github_copied")
                else
                    app.error("clipboard_failed")
                end
                return
            end
            app.window:Popup({
                title = app.ui("github"),
                content = app.ui("github_fallback"),
                boxes = {
                    {
                        title = app.ui("github"),
                        description = repositoryUrl,
                    },
                },
                options = {
                    {
                        text = app.ui("close"),
                        style = "neutral",
                    },
                },
            })
        end,
    })
end
