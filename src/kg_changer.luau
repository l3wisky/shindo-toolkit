return function(app)
    local player = game:GetService("Players").LocalPlayer
    local tab = app.window:CreateTab({
        name = app.ui("tab_kg"),
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
    local selectedPreset = nil

    local function findPlayerValue(path)
        local value = player
        for _, name in ipairs(path) do
            value = value and value:FindFirstChild(name)
        end
        return value
    end

    local function applyValue(path, originalKey, id, displayName)
        local value = findPlayerValue(path)
        if not value then
            app.error("target_missing")
            return
        end
        if app.originals[originalKey] == nil then
            app.originals[originalKey] = value.Value
        end
        value.Value = id
        app.toast("applied", { value = displayName })
    end

    local function restoreValue(path, originalKey)
        local value = findPlayerValue(path)
        local original = app.originals[originalKey]
        if not value or original == nil then
            app.error("original_unavailable")
            return
        end
        value.Value = original
        app.toast("restored", { value = original })
    end

    local function presetOptions()
        if #app.settings.presets == 0 then
            return { app.ui("no_presets") }
        end
        return app.settings.presets
    end

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
        name = app.ui("section_presets"),
    })
    local presetDropdown = tab:CreateDropdown({
        name = app.ui("saved_presets"),
        options = presetOptions(),
        placeholder = app.ui("no_presets"),
        callback = function(name)
            selectedPreset = if bloodlineIds[name] then name else nil
        end,
    })

    tab:CreateButton({
        name = app.ui("apply_preset"),
        icon = app.icons.check,
        callback = function()
            if not selectedPreset then
                app.error("no_preset_selected")
                return
            end
            applyValue(
                { "statz", "main", "kg1" },
                "bloodline",
                bloodlineIds[selectedPreset],
                selectedPreset
            )
        end,
    })
    tab:CreateButton({
        name = app.ui("save_current"),
        callback = function()
            local current = findPlayerValue({ "statz", "main", "kg1" })
            local currentName = nil
            if current then
                for name, id in pairs(bloodlineIds) do
                    if id == current.Value then
                        currentName = name
                        break
                    end
                end
            end
            if not currentName then
                app.error("target_missing")
                return
            end
            if table.find(app.settings.presets, currentName) then
                app.error("preset_duplicate")
                return
            end
            table.insert(app.settings.presets, currentName)
            table.sort(app.settings.presets)
            app.save()
            presetDropdown:Refresh(app.settings.presets)
            app.toast("preset_saved")
        end,
    })
    tab:CreateButton({
        name = app.ui("clear_presets"),
        callback = function()
            app.window:Popup({
                title = app.ui("clear_presets"),
                content = app.ui("clear_presets_question"),
                options = {
                    {
                        text = app.ui("cancel"),
                        style = "neutral",
                    },
                    {
                        text = app.ui("clear"),
                        style = "danger",
                        callback = function()
                            selectedPreset = nil
                            table.clear(app.settings.presets)
                            app.save()
                            presetDropdown:Refresh(presetOptions())
                            app.toast("presets_cleared")
                        end,
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
        icon = app.icons.check,
        callback = function()
            applyValue(
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
            restoreValue({ "statz", "main", "kg1" }, "bloodline")
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
        icon = app.icons.check,
        callback = function()
            applyValue(
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
            restoreValue({ "statz", "breathingstyle" }, "kenjutsu")
        end,
    })
end
