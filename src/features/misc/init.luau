return function(app, modules)
    assert(type(modules) == "table", "Misc feature modules must be a table")

    local tab = app.window:CreateTab({
        name = app.ui("tab_misc"),
        icon = app.icons.misc,
    })

    modules.outfit(app, tab)
    modules.teleport(app, tab)
    modules.date(app, tab, modules.createDateController(app))
    modules.playerInfo(app, tab)
    modules.settings(app, tab)
end
