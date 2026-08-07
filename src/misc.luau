return function(app)
    local Players = game:GetService("Players")
    local TeleportService = game:GetService("TeleportService")
    local localPlayer = Players.LocalPlayer
    local selectedOutfitSlot = 1
    local selectedPlayerName = localPlayer.Name
    local dateBusy = false
    local rejoinFailureConnection = nil

    local tab = app.window:CreateTab({
        name = app.ui("tab_misc"),
        icon = app.icons.misc,
    })

    local function saveSettings()
        if app.save() then
            return true
        end
        app.error("settings_save_failed", {
            reason = app.storage.lastError or "persistent storage is unavailable",
        })
        return false
    end

    local function copy(text, successKey)
        local copied = app.platform.copy(text)
        if copied then
            app.toast(successKey)
            return true
        end
        app.error("clipboard_failed")
        return false
    end

    local function startEvent()
        local candidate = localPlayer:FindFirstChild("startevent")
        if candidate and candidate:IsA("RemoteEvent") then
            return candidate
        end
        return nil
    end

    local function fireStartEvent(command, value)
        local remote = startEvent()
        if not remote then
            app.error("remote_unavailable")
            return false
        end
        local fired, reason = pcall(function()
            remote:FireServer(command, value)
        end)
        if not fired then
            app.error("remote_failed", { reason = tostring(reason) })
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
        rejoinFailureConnection =
            app.trackTemporary(TeleportService.TeleportInitFailed:Connect(function(failedPlayer, _, message)
                if failedPlayer ~= localPlayer then
                    return
                end
                disconnectRejoinFailure()
                app.error("teleport_failed", { reason = tostring(message) })
            end))

        local succeeded, reason = pcall(function()
            TeleportService:Teleport(game.PlaceId, localPlayer)
        end)
        if not succeeded then
            disconnectRejoinFailure()
            app.error("teleport_failed", { reason = tostring(reason) })
            return false
        end
        app.toast("rejoining")
        return true
    end

    local function bandValue()
        return app.values.find(localPlayer, { "statz", "character", "band" })
    end

    local function readValue(target)
        local succeeded, value = pcall(function()
            return target.Value
        end)
        if not succeeded then
            app.error("value_read_failed", { reason = tostring(value) })
            return nil, false
        end
        return value, true
    end

    local function captureDate()
        local band = bandValue()
        if not band then
            app.error("target_missing")
            return nil
        end
        if app.originals.date == nil then
            local original, readSuccessfully = readValue(band)
            if not readSuccessfully then
                return nil
            end
            app.originals.date = original
        end
        return band
    end

    local function waitForBandValue(band, expectedValue)
        local deadline = os.clock() + app.config.timeouts.dateConfirmation
        repeat
            local readSuccessfully, current = pcall(function()
                return band.Value
            end)
            if not readSuccessfully then
                return false
            end
            if current == expectedValue then
                return true
            end
            task.wait(app.config.timeouts.datePollInterval)
        until os.clock() >= deadline
        return false
    end

    local function applyDate(band, value, successKey)
        if not fireStartEvent("band", value) then
            return false
        end
        if not waitForBandValue(band, value) then
            app.error("date_change_unconfirmed")
            return false
        end
        if successKey then
            app.toast(successKey)
        end
        return true
    end

    local function runDateOperation(callback)
        if dateBusy then
            app.error("operation_busy")
            return false
        end

        dateBusy = true
        local succeeded, result = xpcall(callback, function(reason)
            return tostring(reason)
        end)
        dateBusy = false

        if not succeeded then
            app.error("operation_failed", { reason = result })
            return false
        end
        return result ~= false
    end

    local function rollbackAndRejoin()
        runDateOperation(function()
            local band = captureDate()
            if not band then
                return false
            end
            if not applyDate(band, app.config.game.rollbackBand) then
                return false
            end
            return rejoin()
        end)
    end

    tab:CreateSection({
        name = app.ui("section_outfit"),
    })
    tab:CreateDropdown({
        name = app.ui("outfit_slot"),
        options = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" },
        value = tostring(selectedOutfitSlot),
        forgetState = true,
        callback = function(value)
            selectedOutfitSlot = tonumber(value) or 1
        end,
    })
    tab:CreateButton({
        name = app.ui("load_outfit"),
        callback = function()
            fireStartEvent("loadoutfit", selectedOutfitSlot)
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
            fireStartEvent("arenateleport", app.config.game.homePlaceId)
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
        callback = function()
            runDateOperation(function()
                local band = captureDate()
                if not band then
                    return false
                end
                return applyDate(band, app.config.game.rollbackBand, "rollback_applied")
            end)
        end,
    })
    dateActions:CreateButton({
        name = app.ui("restore_date"),
        callback = function()
            runDateOperation(function()
                if app.originals.date == nil then
                    app.error("original_unavailable")
                    return false
                end
                local band = bandValue()
                if not band then
                    app.error("target_missing")
                    return false
                end
                return applyDate(band, app.originals.date, "original_date_restored")
            end)
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
                        callback = rollbackAndRejoin,
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
        if table.find(names, selectedPlayerName) == nil then
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
        options = playerNames(nil),
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
                        copy(resolvedCode, "ps_copied")
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
                saveSettings()
                app.window:SetLocale(language)
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
                saveSettings()
                app.window:ChangeTheme(theme)
            end
        end,
    })
    tab:CreateToggle({
        name = app.ui("notifications"),
        value = app.settings.notifications,
        forgetState = true,
        callback = function(value)
            app.settings.notifications = value
            saveSettings()
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
                            task.defer(function()
                                app.rebuild()
                                app.toast("settings_reset")
                            end)
                        end,
                    },
                },
            })
        end,
    })

    tab:CreateButton({
        name = app.ui("diagnostics"),
        description = app.ui("diagnostics_description"),
        callback = function()
            local snapshot = app.diagnostics.snapshot()
            local function status(value)
                return app.t(if value then "available" else "unavailable")
            end

            app.window:Popup({
                title = app.t("diagnostics"),
                content = app.t("diagnostics_description"),
                boxes = {
                    {
                        title = app.t("diagnostics_runtime"),
                        description = table.concat({
                            "version: " .. snapshot.version,
                            "channel: " .. snapshot.channel,
                            "place: " .. snapshot.placeId,
                            "rayfield: " .. snapshot.rayfield,
                        }, "\n"),
                    },
                    {
                        title = app.t("diagnostics_capabilities"),
                        description = table.concat({
                            "filesystem: " .. status(snapshot.filesystem),
                            "clipboard: " .. status(snapshot.clipboard),
                        }, "\n"),
                    },
                    {
                        title = app.t("diagnostics_targets"),
                        description = table.concat({
                            "startevent: " .. status(snapshot.startEvent),
                            "bloodline: " .. status(snapshot.bloodline),
                            "kenjutsu: " .. status(snapshot.kenjutsu),
                            "date: " .. status(snapshot.date),
                            "rcgenkai: " .. status(snapshot.rcgenkai),
                        }, "\n"),
                    },
                },
                options = {
                    {
                        text = app.ui("close"),
                        style = "neutral",
                    },
                    {
                        text = app.ui("copy_diagnostics"),
                        style = "primary",
                        callback = function()
                            copy(app.diagnostics.report(), "diagnostics_copied")
                        end,
                    },
                },
            })
        end,
    })

    tab:CreateButton({
        name = app.ui("github"),
        description = app.ui("github_description"),
        icon = app.icons.github,
        callback = function()
            if app.platform.capabilities.clipboard then
                copy(app.config.repositoryUrl, "github_copied")
                return
            end
            app.window:Popup({
                title = app.ui("github"),
                content = app.ui("github_fallback"),
                boxes = {
                    {
                        title = app.ui("github"),
                        description = app.config.repositoryUrl,
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
