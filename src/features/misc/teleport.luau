return function(app, tab)
    tab:CreateSection({
        name = app.ui("section_teleport"),
    })
    local actions = tab:CreateGroup({
        direction = "row",
    })
    actions:CreateButton({
        name = app.ui("home"),
        callback = function()
            app.game.fireStartEvent("arenateleport", app.config.game.homePlaceId)
        end,
    })
    actions:CreateButton({
        name = app.ui("rejoin"),
        callback = app.game.rejoin,
    })
end
