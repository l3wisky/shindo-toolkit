return function(app, tab)
    local selectedPlayerName = app.game.localPlayer.Name

    local function copy(text, successKey)
        local copied = app.platform.copy(text)
        if copied then
            app.toast(successKey)
            return true
        end
        app.error("clipboard_failed")
        return false
    end

    tab:CreateSection({
        name = app.ui("section_player"),
    })

    local playersDropdown
    local function refreshPlayers(excludedPlayer)
        local names = app.game.playerNames(excludedPlayer)
        if table.find(names, selectedPlayerName) == nil then
            if app.game.localPlayer ~= excludedPlayer and table.find(names, app.game.localPlayer.Name) then
                selectedPlayerName = app.game.localPlayer.Name
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
        options = app.game.playerNames(nil),
        value = selectedPlayerName,
        forgetState = true,
        callback = function(name)
            if app.game.findPlayer(name) then
                selectedPlayerName = name
            end
        end,
    })

    tab:CreateButton({
        name = app.ui("view_player"),
        callback = function()
            local target = app.game.findPlayer(selectedPlayerName)
            if not target then
                app.error("player_unavailable")
                return
            end

            local info = app.game.getPlayerInfo(target)
            local resolvedDays = info.days or app.t("unavailable")
            local options = {
                {
                    text = app.ui("close"),
                    style = "neutral",
                },
            }
            if info.code then
                table.insert(options, {
                    text = app.ui("copy_ps"),
                    style = "primary",
                    callback = function()
                        copy(info.code, "ps_copied")
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
                        description = info.code or app.t("unavailable"),
                    },
                },
                options = options,
            })
        end,
    })

    app.game.onPlayerAdded(function()
        refreshPlayers(nil)
    end)
    app.game.onPlayerRemoving(function(removingPlayer)
        refreshPlayers(removingPlayer)
    end)
end
