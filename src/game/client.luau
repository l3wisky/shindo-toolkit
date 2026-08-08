return function(app, dependencies)
    dependencies = dependencies or {}

    local Players = dependencies.Players or game:GetService("Players")
    local TeleportService = dependencies.TeleportService or game:GetService("TeleportService")
    local world = dependencies.Workspace or workspace
    local placeId = dependencies.PlaceId or game.PlaceId
    local localPlayer = dependencies.LocalPlayer or Players.LocalPlayer
    assert(localPlayer ~= nil, "Shindo Toolkit game client requires LocalPlayer")

    local paths = {
        startEvent = "Players.LocalPlayer.startevent",
        dateBand = "Players.LocalPlayer.statz.character.band",
        kenjutsu = "Players.LocalPlayer.statz.breathingstyle",
        rcgenkai = "workspace.RCGENKAI.item1",
    }

    local client = {
        localPlayer = localPlayer,
        paths = paths,
    }
    local rejoinFailureConnection = nil

    local function find(root, path)
        local current = root
        for _, name in ipairs(path) do
            if not current or type(current.FindFirstChild) ~= "function" then
                return nil
            end
            current = current:FindFirstChild(name)
        end
        return current
    end

    local function disconnectRejoinFailure()
        local connection = rejoinFailureConnection
        rejoinFailureConnection = nil
        if connection and connection.Connected then
            pcall(function()
                connection:Disconnect()
            end)
        end
    end

    local function readTextValue(target)
        if not target then
            return nil
        end
        local succeeded, value = pcall(function()
            return target.Value
        end)
        if not succeeded or value == nil then
            return nil
        end
        local text = tostring(value)
        return if text ~= "" then text else nil
    end

    function client.bloodlineSlotPath(index)
        return "Players.LocalPlayer.statz.main.kg" .. tostring(index)
    end

    function client.getBloodlineSlot(index)
        return find(localPlayer, { "statz", "main", "kg" .. tostring(index) })
    end

    function client.getKenjutsu()
        return find(localPlayer, { "statz", "breathingstyle" })
    end

    function client.getRcgenkaiItem()
        return find(world, { "RCGENKAI", "item1" })
    end

    function client.getDateBand()
        return find(localPlayer, { "statz", "character", "band" })
    end

    function client.fireStartEvent(command, value)
        local candidate = localPlayer:FindFirstChild("startevent")
        if not candidate or not candidate:IsA("RemoteEvent") then
            return app.missing("remote_unavailable", paths.startEvent)
        end

        local fired, reason = pcall(function()
            candidate:FireServer(command, value)
        end)
        if not fired then
            app.error("remote_failed", { reason = tostring(reason) })
            return false
        end
        return true
    end

    function client.rejoin()
        disconnectRejoinFailure()

        local connected, connection = pcall(function()
            return TeleportService.TeleportInitFailed:Connect(function(failedPlayer, _, message)
                if failedPlayer ~= localPlayer then
                    return
                end
                disconnectRejoinFailure()
                app.error("teleport_failed", { reason = tostring(message) })
            end)
        end)
        if connected and connection then
            rejoinFailureConnection = app.trackTemporary(connection)
        end

        local succeeded, reason = pcall(function()
            TeleportService:Teleport(placeId, localPlayer)
        end)
        if not succeeded then
            disconnectRejoinFailure()
            app.error("teleport_failed", { reason = tostring(reason) })
            return false
        end

        app.toast("rejoining")
        return true
    end

    function client.findPlayer(name)
        if type(name) ~= "string" then
            return nil
        end
        return Players:FindFirstChild(name)
    end

    function client.playerNames(excludedPlayer)
        local names = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= excludedPlayer then
                table.insert(names, player.Name)
            end
        end
        table.sort(names)
        return names
    end

    function client.getPlayerInfo(player)
        local statz = player and player:FindFirstChild("statz")
        local ps = statz and statz:FindFirstChild("ps")
        return {
            code = readTextValue(ps and ps:FindFirstChild("mycode")),
            days = readTextValue(statz and statz:FindFirstChild("gamedays")),
        }
    end

    function client.onPlayerAdded(callback)
        return app.trackTemporary(Players.PlayerAdded:Connect(callback))
    end

    function client.onPlayerRemoving(callback)
        return app.trackTemporary(Players.PlayerRemoving:Connect(callback))
    end

    return client
end
