return function(app)
    local Players = game:GetService("Players")
    local TeleportService = game:GetService("TeleportService")
    local player = Players.LocalPlayer
    local tab = app.window:CreateTab({ name = app.t("tab_misc") })
    local selectedPlayer = player.Name
    local currentCode = nil
    local rejoinFailureConnection = nil

    local function remote(command, value)
        local event = player:FindFirstChild("startevent")
        if not event or not event.FireServer then app.notify("error", "target_missing"); return false end
        local ok, reason = pcall(function() event:FireServer(command, value) end)
        if not ok then app.notify("error", "request_failed", { reason = reason }); return false end
        return true
    end
    local function rejoin()
        if rejoinFailureConnection then rejoinFailureConnection:Disconnect(); rejoinFailureConnection = nil end
        rejoinFailureConnection = app.trackTemporary(TeleportService.TeleportInitFailed:Connect(function(failedPlayer, _, message)
            if failedPlayer ~= player then return end
            if rejoinFailureConnection then rejoinFailureConnection:Disconnect(); rejoinFailureConnection = nil end
            app.notify("error", "request_failed", { reason = message })
        end))
        local ok, reason = pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
        if not ok then
            if rejoinFailureConnection then rejoinFailureConnection:Disconnect(); rejoinFailureConnection = nil end
            app.notify("error", "request_failed", { reason = reason })
            return false
        end
        app.notify("success", "rejoining")
        return true
    end
    local function bandValue()
        local statz = player:FindFirstChild("statz")
        local character = statz and statz:FindFirstChild("character")
        return character and character:FindFirstChild("band")
    end
    local function rollback()
        local band = bandValue()
        if not band then app.notify("error", "target_missing"); return false end
        if app.originals.date == nil then app.originals.date = band.Value end
        local invalid = string.char(128)
        if not remote("band", invalid) then return false end
        local deadline = os.clock() + 4
        repeat
            if tostring(band.Value) == invalid then app.notify("success", "date_saved"); return true end
            task.wait(0.08)
        until os.clock() >= deadline
        app.notify("error", "rollback_unconfirmed")
        return false
    end

    tab:CreateSection({ name = app.t("section_outfit") })
    local slots = { "1", "2", "3", "4", "5", "6", "7", "8", "9" }
    tab:CreateDropdown({
        name = app.t("outfit_slot"), options = slots, value = tostring(app.settings.outfit_slot), forgetState = true,
        callback = function(value) app.settings.outfit_slot = tonumber(value) or 1; app.save() end,
    })
    tab:CreateButton({ name = app.t("load_outfit"), callback = function() remote("loadoutfit", app.settings.outfit_slot) end })

    tab:CreateSection({ name = app.t("section_teleport") })
    tab:CreateButton({ name = app.t("home"), callback = function() remote("arenateleport", 5451410109) end })
    tab:CreateButton({ name = app.t("rejoin"), callback = rejoin })

    tab:CreateSection({ name = app.t("section_date") })
    tab:CreateButton({ name = app.t("rollback_date"), callback = rollback })
    tab:CreateButton({ name = app.t("restore_date"), callback = function()
        if app.originals.date == nil then app.notify("error", "original_unavailable"); return end
        if remote("band", app.originals.date) then app.notify("success", "restored", { value = app.originals.date }) end
    end })
    tab:CreateButton({ name = app.t("rollback_rejoin"), callback = function() if rollback() then rejoin() end end })

    tab:CreateSection({ name = app.t("section_player") })
    local function playerNames()
        local names = {}; for _, target in ipairs(Players:GetPlayers()) do table.insert(names, target.Name) end
        table.sort(names); return names
    end
    local codeDisplay = tab:CreateInput({ name = app.t("latest_ps_label"), value = app.t("unavailable"), forgetState = true, callback = function() end })
    local daysDisplay = tab:CreateInput({ name = app.t("game_days_label"), value = app.t("unavailable"), forgetState = true, callback = function() end })
    local function refreshInfo()
        local target = Players:FindFirstChild(selectedPlayer)
        local statz = target and target:FindFirstChild("statz")
        local ps = statz and statz:FindFirstChild("ps")
        local code = ps and ps:FindFirstChild("mycode")
        local days = statz and statz:FindFirstChild("gamedays")
        local resolvedCode = code and tostring(code.Value) or ""
        local resolvedDays = days and tostring(days.Value) or ""
        currentCode = resolvedCode ~= "" and resolvedCode or nil
        codeDisplay:Set(currentCode or app.t("unavailable"), true)
        daysDisplay:Set(resolvedDays ~= "" and resolvedDays or app.t("unavailable"), true)
    end
    local names = playerNames()
    local playersDropdown = tab:CreateDropdown({
        name = app.t("player"), options = names, value = selectedPlayer, forgetState = true,
        callback = function(name) selectedPlayer = name; refreshInfo() end,
    })
    tab:CreateButton({ name = app.t("refresh_players"), callback = function()
        local refreshed = playerNames(); playersDropdown:Refresh(refreshed)
        if not Players:FindFirstChild(selectedPlayer) then selectedPlayer = refreshed[1] end
        playersDropdown:Set(selectedPlayer, true); refreshInfo()
    end })
    tab:CreateButton({ name = app.t("copy_ps"), callback = function()
        if not currentCode then app.notify("error", "ps_unavailable"); return end
        if not setclipboard then app.notify("error", "clipboard_unavailable"); return end
        local ok = pcall(setclipboard, currentCode)
        app.notify(ok and "success" or "error", ok and "copied" or "clipboard_unavailable")
    end })
    refreshInfo()

    tab:CreateSection({ name = app.t("section_settings") })
    tab:CreateDropdown({
        name = app.t("language"), options = { app.t("english"), app.t("russian") },
        value = app.settings.language == "ru" and app.t("russian") or app.t("english"), forgetState = true,
        callback = function(choice)
            local language = choice == app.t("russian") and "ru" or "en"
            if language ~= app.settings.language then app.settings.language = language; app.save(); app.rebuild() end
        end,
    })
    local themeLabels, themeIdByLabel = {}, {}
    for _, theme in ipairs(app.themes) do
        local label = app.t(theme.labelKey)
        table.insert(themeLabels, label); themeIdByLabel[label] = theme.id
    end
    local selectedThemeLabel
    for _, theme in ipairs(app.themes) do if theme.id == app.settings.theme then selectedThemeLabel = app.t(theme.labelKey) end end
    tab:CreateDropdown({
        name = app.t("theme"), options = themeLabels, value = selectedThemeLabel, forgetState = true,
        callback = function(label)
            local theme = themeIdByLabel[label]
            if theme and theme ~= app.settings.theme then
                app.settings.theme = theme; app.save(); app.window:ChangeTheme(theme)
            end
        end,
    })
    tab:CreateToggle({
        name = app.t("notifications"), value = app.settings.notifications, forgetState = true,
        callback = function(value) app.settings.notifications = value; app.save() end,
    })
    tab:CreateButton({ name = app.t("reset_settings"), callback = function()
        local reset = app.storage.reset()
        app.rebuild()
        app.notify(reset and "success" or "error", reset and "settings_reset" or "settings_reset_failed")
    end })
end
