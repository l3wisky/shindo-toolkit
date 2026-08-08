local createGameClient = require("../../src/game/client")
local node = require("../support/node")

local function signal()
    local listeners = {}
    local event = {}

    function event:Connect(callback)
        local connection = {
            Connected = true,
        }
        function connection:Disconnect()
            self.Connected = false
        end
        table.insert(listeners, {
            connection = connection,
            callback = callback,
        })
        return connection
    end

    function event:Fire(...)
        for _, listener in ipairs(listeners) do
            if listener.connection.Connected then
                listener.callback(...)
            end
        end
    end

    return event
end

return function(check)
    local kg1 = node("kg")
    local kenjutsu = node("ken")
    local band = node("date")
    local code = node("PS-CODE")
    local days = node(42)
    local remote = node(nil)
    local remoteFailure = nil
    local firedCommand = nil
    local firedValue = nil

    function remote:IsA(className)
        return className == "RemoteEvent"
    end
    function remote:FireServer(command, value)
        if remoteFailure then
            error(remoteFailure)
        end
        firedCommand = command
        firedValue = value
    end

    local localPlayer = node(nil, {
        startevent = remote,
        statz = node(nil, {
            main = node(nil, { kg1 = kg1 }),
            breathingstyle = kenjutsu,
            character = node(nil, { band = band }),
            ps = node(nil, { mycode = code }),
            gamedays = days,
        }),
    })
    localPlayer.Name = "Local"

    local alpha = node()
    alpha.Name = "Alpha"
    local zulu = node()
    zulu.Name = "Zulu"

    local playerAdded = signal()
    local playerRemoving = signal()
    local players = {
        LocalPlayer = localPlayer,
        PlayerAdded = playerAdded,
        PlayerRemoving = playerRemoving,
        children = {
            Local = localPlayer,
            Alpha = alpha,
            Zulu = zulu,
        },
    }
    function players:GetPlayers()
        return { zulu, localPlayer, alpha }
    end
    function players:FindFirstChild(name)
        return self.children[name]
    end

    local teleportInitFailed = signal()
    local teleportFailure = nil
    local teleportedPlace = nil
    local teleportedPlayer = nil
    local teleportService = {
        TeleportInitFailed = teleportInitFailed,
    }
    function teleportService:Teleport(placeId, player)
        if teleportFailure then
            error(teleportFailure)
        end
        teleportedPlace = placeId
        teleportedPlayer = player
    end

    local rcItem = node("rc")
    local world = node(nil, {
        RCGENKAI = node(nil, { item1 = rcItem }),
    })

    local messages = {}
    local tracked = 0
    local app = {
        missing = function(key, path)
            table.insert(messages, "missing:" .. key .. ":" .. path)
            return false
        end,
        error = function(key, values)
            table.insert(messages, "error:" .. key .. ":" .. tostring(values and values.reason))
        end,
        toast = function(key)
            table.insert(messages, "toast:" .. key)
        end,
        trackTemporary = function(connection)
            tracked += 1
            return connection
        end,
    }

    local client = createGameClient(app, {
        Players = players,
        TeleportService = teleportService,
        Workspace = world,
        PlaceId = 5451410109,
        LocalPlayer = localPlayer,
    })

    check(client.getBloodlineSlot(1) == kg1, "bloodline target should resolve through the adapter")
    check(client.getKenjutsu() == kenjutsu, "kenjutsu target should resolve through the adapter")
    check(client.getRcgenkaiItem() == rcItem, "RC target should resolve through the adapter")
    check(client.getDateBand() == band, "date target should resolve through the adapter")
    check(
        client.bloodlineSlotPath(1) == "Players.LocalPlayer.statz.main.kg1",
        "bloodline path should be centralized"
    )

    check(client.fireStartEvent("band", "new"), "valid start event should fire")
    check(firedCommand == "band" and firedValue == "new", "start event arguments should be preserved")

    remoteFailure = "remote exploded"
    check(not client.fireStartEvent("band", "bad"), "remote exceptions should fail safely")
    check(messages[#messages]:match("^error:remote_failed:"), "remote exceptions should be reported")
    remoteFailure = nil

    localPlayer.children.startevent = nil
    check(not client.fireStartEvent("band", "missing"), "missing remote should fail")
    check(
        messages[#messages] == "missing:remote_unavailable:Players.LocalPlayer.startevent",
        "missing remote should report its canonical path"
    )
    localPlayer.children.startevent = remote

    local names = client.playerNames(localPlayer)
    check(names[1] == "Alpha" and names[2] == "Zulu", "player names should be sorted and filtered")
    check(client.findPlayer("Alpha") == alpha, "player lookup should stay inside the adapter")
    check(client.findPlayer(nil) == nil, "invalid player names should not reach the service")

    local info = client.getPlayerInfo(localPlayer)
    check(info.code == "PS-CODE", "player code should be read through the adapter")
    check(info.days == "42", "game days should be normalized to text")

    teleportFailure = "teleport exploded"
    check(not client.rejoin(), "synchronous teleport failures should fail safely")
    check(messages[#messages]:match("^error:teleport_failed:"), "teleport failure should be reported")
    teleportFailure = nil

    check(client.rejoin(), "rejoin should start when TeleportService succeeds")
    check(teleportedPlace == 5451410109, "rejoin should target the current place")
    check(teleportedPlayer == localPlayer, "rejoin should target LocalPlayer")
    check(messages[#messages] == "toast:rejoining", "successful rejoin should notify the user")

    local beforeFailure = #messages
    teleportInitFailed:Fire(alpha, nil, "other player")
    check(#messages == beforeFailure, "other players' teleport failures should be ignored")
    teleportInitFailed:Fire(localPlayer, nil, "denied")
    check(messages[#messages] == "error:teleport_failed:denied", "async teleport failure should be reported")

    local added = nil
    client.onPlayerAdded(function(player)
        added = player
    end)
    playerAdded:Fire(alpha)
    check(added == alpha, "player-added callbacks should be connected through the adapter")
    check(tracked >= 3, "temporary game connections should be lifecycle-tracked")
end
