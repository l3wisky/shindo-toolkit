return function(app, tab, controller)
    tab:CreateSection({
        name = app.ui("section_date"),
    })
    local actions = tab:CreateGroup({
        direction = "row",
    })
    actions:CreateButton({
        name = app.ui("rollback_date"),
        callback = controller.rollback,
    })
    actions:CreateButton({
        name = app.ui("restore_date"),
        callback = controller.restore,
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
                        callback = controller.rollbackAndRejoin,
                    },
                },
            })
        end,
    })
end
