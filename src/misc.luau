return function(app)
    local DATE_CONFIRM_TIMEOUT = 10
    local STARTEVENT_TIMEOUT = 15
    local Players = game:GetService("Players")
    local TeleportService = game:GetService("TeleportService")
    local localPlayer = Players.LocalPlayer
    local startEvent = localPlayer:WaitForChild("startevent", STARTEVENT_TIMEOUT)
    if not startEvent then
        if app.window and app.window.unloaded == false then
            app.window:Unload()
        end
        error("Shindo Toolkit: LocalPlayer.startevent was not found")
    end
    local repositoryUrl = "https://github.com/l3wisky/shindo-toolkit"
    local selectedOutfitSlot = 1
    local dateBusy = false

    local tab = app.window:CreateTab({
        name = app.ui("tab_misc"),
        icon = app.icons.misc,
    })
    local selectedPlayerName = localPlayer.Name
    local rejoinFailureConnection = nil

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
            app.error("teleport_failed", { reason = message })
        end))

        local succeeded, reason = pcall(function()
            TeleportService:Teleport(game.PlaceId, localPlayer)
        end)
        if not succeeded then
            disconnectRejoinFailure()
            app.error("teleport_failed", { reason = reason })
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

    local function captureDate()
        local band = bandValue()
        if not band then
            app.error("target_missing")
            return nil
        end
        if app.originals.date == nil then
            app.originals.date = band.Value
        end
        return band
    end

    local function waitForBandValue(band, expectedValue)
        local deadline = os.clock() + DATE_CONFIRM_TIMEOUT
        repeat
            if band.Value == expectedValue then
                return true
            end
            task.wait(0.08)
        until os.clock() >= deadline
        return false
    end

    local function applyDate(band, value, successKey)
        startEvent:FireServer("band", value)
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
            return
        end
        dateBusy = true
        callback()
        dateBusy = false
    end

    local function rollbackAndRejoin()
        runDateOperation(function()
            local band = captureDate()
            if band and applyDate(band, string.char(128)) then
                rejoin()
            end
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
            startEvent:FireServer("loadoutfit", selectedOutfitSlot)
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
            startEvent:FireServer("arenateleport", 5451410109)
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
                if band then
                    applyDate(band, string.char(128), "rollback_applied")
                end
            end)
        end,
    })
    dateActions:CreateButton({
        name = app.ui("restore_date"),
        callback = function()
            runDateOperation(function()
                if app.originals.date == nil then
                    app.error("original_unavailable")
                    return
                end
                local band = bandValue()
                if not band then
                    app.error("target_missing")
                    return
                end
                applyDate(band, app.originals.date, "original_date_restored")
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

    local function selectedPlayerData()
        local target = selectedPlayerName and Players:FindFirstChild(selectedPlayerName)
        if not target then
            return nil, 0, nil
        end

        local statz = target:FindFirstChild("statz")
        local daysValue = statz and statz:FindFirstChild("gamedays")
        local ps = statz and statz:FindFirstChild("ps")
        local codeValue = ps and ps:FindFirstChild("mycode")
        local code = codeValue and tostring(codeValue.Value) or ""

        return target, tonumber(daysValue and daysValue.Value) or 0, if code ~= "" then code else nil
    end

    local playersDropdown
    local gameDaysStat

    local function refreshPlayerData()
        local _, days = selectedPlayerData()
        if gameDaysStat then
            gameDaysStat:Set(days)
        end
    end

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
        refreshPlayerData()
    end

    playersDropdown = tab:CreateDropdown({
        name = app.ui("player"),
        options = playerNames(),
        value = selectedPlayerName,
        forgetState = true,
        callback = function(name)
            if Players:FindFirstChild(name) then
                selectedPlayerName = name
                refreshPlayerData()
            end
        end,
    })

    local _, initialGameDays = selectedPlayerData()
    gameDaysStat = tab:CreateStat({
        name = app.ui("game_days_label"),
        value = initialGameDays,
        numberEasing = true,
    })

    tab:CreateButton({
        name = app.ui("copy_ps"),
        callback = function()
            local target, _, code = selectedPlayerData()
            if not target then
                app.error("player_unavailable")
                return
            end
            if not code then
                app.error("ps_unavailable")
                return
            end
            if type(setclipboard) ~= "function" then
                app.error("clipboard_failed")
                return
            end
            local copied = pcall(setclipboard, code)
            if copied then
                app.toast("ps_copied")
            else
                app.error("clipboard_failed")
            end
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
        name = app.ui("github"),
        description = app.ui("github_description"),
        icon = app.icons.github,
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
