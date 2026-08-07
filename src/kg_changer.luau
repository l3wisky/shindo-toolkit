return function(app)
    local player = game:GetService("Players").LocalPlayer
    local tab = app.window:CreateTab({
        name = app.ui("tab_kg"),
        icon = app.icons.kg,
    })

    local bloodlineIds = {}
    local bloodlineNames = {}
    for _, bloodline in ipairs(app.data.bloodlines) do
        bloodlineIds[bloodline.name] = bloodline.id
        table.insert(bloodlineNames, bloodline.name)
    end
    table.sort(bloodlineNames)

    local kenjutsuIds = {}
    local kenjutsuNames = {}
    for _, kenjutsu in ipairs(app.data.kenjutsu) do
        kenjutsuIds[kenjutsu.name] = kenjutsu.id
        table.insert(kenjutsuNames, kenjutsu.name)
    end
    table.sort(kenjutsuNames)

    local selectedBloodline = bloodlineNames[1]
    local selectedKenjutsu = kenjutsuNames[1]

    tab:CreateButton({
        name = app.ui("about_kg"),
        description = app.ui("kg_elements"),
        callback = function()
            app.window:Popup({
                title = app.ui("about_kg"),
                content = app.ui("kg_elements"),
                boxes = {
                    {
                        title = app.ui("kg_slots_title"),
                        description = app.ui("kg_slots"),
                    },
                    {
                        title = app.ui("kg_kenjutsu_title"),
                        description = app.ui("kg_kenjutsu"),
                    },
                },
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
        name = app.ui("section_bloodline"),
    })
    tab:CreateDropdown({
        name = app.ui("bloodline_list"),
        options = bloodlineNames,
        value = selectedBloodline,
        forgetState = true,
        callback = function(name)
            if bloodlineIds[name] then
                selectedBloodline = name
            end
        end,
    })
    local bloodlineActions = tab:CreateGroup({
        direction = "row",
    })
    bloodlineActions:CreateButton({
        name = app.ui("apply_bloodline"),
        callback = function()
            app.values.apply(
                player,
                { "statz", "main", "kg1" },
                "bloodline",
                bloodlineIds[selectedBloodline],
                selectedBloodline
            )
        end,
    })
    bloodlineActions:CreateButton({
        name = app.ui("restore_bloodline"),
        callback = function()
            app.values.restore(player, { "statz", "main", "kg1" }, "bloodline")
        end,
    })

    tab:CreateSection({
        name = app.ui("section_kenjutsu"),
    })
    tab:CreateDropdown({
        name = app.ui("kenjutsu_list"),
        options = kenjutsuNames,
        value = selectedKenjutsu,
        forgetState = true,
        callback = function(name)
            if kenjutsuIds[name] then
                selectedKenjutsu = name
            end
        end,
    })
    local kenjutsuActions = tab:CreateGroup({
        direction = "row",
    })
    kenjutsuActions:CreateButton({
        name = app.ui("apply_kenjutsu"),
        callback = function()
            app.values.apply(
                player,
                { "statz", "breathingstyle" },
                "kenjutsu",
                kenjutsuIds[selectedKenjutsu],
                selectedKenjutsu
            )
        end,
    })
    kenjutsuActions:CreateButton({
        name = app.ui("restore_kenjutsu"),
        callback = function()
            app.values.restore(player, { "statz", "breathingstyle" }, "kenjutsu")
        end,
    })
end
