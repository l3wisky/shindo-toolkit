return function(app)
    local tab = app.window:CreateTab({
        name = app.ui("tab_rc"),
        icon = app.icons.rcgenkai,
    })

    local bloodlineNames = {}
    local bloodlineIds = {}
    for _, bloodline in ipairs(app.data.bloodlines) do
        table.insert(bloodlineNames, bloodline.name)
        bloodlineIds[bloodline.name] = bloodline.id
    end
    table.sort(bloodlineNames)
    local selectedBloodline = bloodlineNames[1]

    tab:CreateButton({
        name = app.ui("about_rc"),
        description = app.ui("rc_guidance"),
        callback = function()
            app.window:Popup({
                title = app.ui("about_rc"),
                content = app.ui("rc_explanation"),
                options = {
                    {
                        text = app.ui("close"),
                        style = "neutral",
                    },
                },
            })
        end,
    })

    tab:CreateSection({
        name = app.ui("section_rc"),
    })
    tab:CreateDropdown({
        name = app.ui("rc_bloodline"),
        options = bloodlineNames,
        value = selectedBloodline,
        forgetState = true,
        callback = function(name)
            if bloodlineIds[name] then
                selectedBloodline = name
            end
        end,
    })

    local actions = tab:CreateGroup({
        direction = "row",
    })
    actions:CreateButton({
        name = app.ui("apply_rc"),
        callback = function()
            app.values.apply(
                workspace,
                { "RCGENKAI", "item1" },
                "rcgenkai",
                bloodlineIds[selectedBloodline],
                selectedBloodline
            )
        end,
    })
    actions:CreateButton({
        name = app.ui("restore_rc"),
        callback = function()
            app.values.restore(workspace, { "RCGENKAI", "item1" }, "rcgenkai")
        end,
    })
end
