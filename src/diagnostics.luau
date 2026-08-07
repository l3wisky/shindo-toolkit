return function(app)
    local Players = game:GetService("Players")

    local diagnostics = {}

    local function exists(root, path)
        return app.values.find(root, path) ~= nil
    end

    function diagnostics.snapshot()
        local player = Players.LocalPlayer
        local startEvent = player and player:FindFirstChild("startevent")
        return {
            version = app.version,
            channel = if app.development then "dev" else "stable",
            placeId = tostring(game.PlaceId),
            rayfield = app.config.rayfield.version,
            filesystem = app.platform.capabilities.filesystem,
            clipboard = app.platform.capabilities.clipboard,
            startEvent = startEvent ~= nil and startEvent:IsA("RemoteEvent"),
            bloodline = player ~= nil and exists(player, { "statz", "main", "kg1" }),
            kenjutsu = player ~= nil and exists(player, { "statz", "breathingstyle" }),
            date = player ~= nil and exists(player, { "statz", "character", "band" }),
            rcgenkai = exists(workspace, { "RCGENKAI", "item1" }),
        }
    end

    function diagnostics.report()
        local snapshot = diagnostics.snapshot()
        local function status(value)
            return if value then "available" else "unavailable"
        end
        return table.concat({
            "Shindo Toolkit diagnostics",
            "version=" .. snapshot.version,
            "channel=" .. snapshot.channel,
            "place_id=" .. snapshot.placeId,
            "rayfield=" .. snapshot.rayfield,
            "filesystem=" .. status(snapshot.filesystem),
            "clipboard=" .. status(snapshot.clipboard),
            "startevent=" .. status(snapshot.startEvent),
            "bloodline_target=" .. status(snapshot.bloodline),
            "kenjutsu_target=" .. status(snapshot.kenjutsu),
            "date_target=" .. status(snapshot.date),
            "rcgenkai_target=" .. status(snapshot.rcgenkai),
        }, "\n")
    end

    return diagnostics
end
