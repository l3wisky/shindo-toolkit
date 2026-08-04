return function(app)
    local tab = app.window:CreateTab({
        name = app.ui("tab_rc"),
    })

    local bloodlineNames = {}
    local bloodlineIds = {}
    for _, bloodline in ipairs(app.data.bloodlines) do
        table.insert(bloodlineNames, bloodline.name)
        bloodlineIds[bloodline.name] = bloodline.id
    end
    table.sort(bloodlineNames)
    local selectedBloodline = bloodlineNames[1]

    local function item1Value()
        local rcgenkai = workspace:FindFirstChild("RCGENKAI")
        return rcgenkai and rcgenkai:FindFirstChild("item1")
    end

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
        icon = app.icons.check,
        callback = function()
            local value = item1Value()
            if not value then
                app.error("target_missing")
                return
            end
            if app.originals.rcgenkai == nil then
                app.originals.rcgenkai = value.Value
            end
            value.Value = bloodlineIds[selectedBloodline]
            app.toast("applied", { value = selectedBloodline })
        end,
    })
    actions:CreateButton({
        name = app.ui("restore_rc"),
        callback = function()
            local value = item1Value()
            local original = app.originals.rcgenkai
            if not value or original == nil then
                app.error("original_unavailable")
                return
            end
            value.Value = original
            app.toast("restored", { value = original })
        end,
    })
end
