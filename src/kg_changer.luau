return function(app)
    local player = game:GetService("Players").LocalPlayer
    local tab = app.window:CreateTab({ name = app.t("tab_kg") })
    local bloodlineByName, bloodlineNames = {}, {}
    local kenjutsuByName, kenjutsuNames = {}, {}
    for _, item in ipairs(app.data.bloodlines) do bloodlineByName[item.name] = item.id; table.insert(bloodlineNames, item.name) end
    for _, item in ipairs(app.data.kenjutsu) do kenjutsuByName[item.name] = item.id; table.insert(kenjutsuNames, item.name) end
    table.sort(bloodlineNames); table.sort(kenjutsuNames)
    local selectedBloodline, selectedKenjutsu, selectedPreset = bloodlineNames[1], kenjutsuNames[1], nil

    local function stat(path)
        local value = player
        for _, name in ipairs(path) do value = value and value:FindFirstChild(name) end
        return value
    end
    local function apply(path, originalKey, id, name)
        local value = stat(path)
        if not value then app.notify("error", "target_missing"); return end
        if app.originals[originalKey] == nil then app.originals[originalKey] = value.Value end
        value.Value = id
        app.notify("success", "applied", { value = name })
    end
    local function restore(path, originalKey)
        local value, original = stat(path), app.originals[originalKey]
        if not value or original == nil then app.notify("error", "original_unavailable"); return end
        value.Value = original
        app.notify("success", "restored", { value = original })
    end
    local function presetOptions()
        return #app.settings.presets > 0 and app.settings.presets or { app.t("no_presets") }
    end

    tab:CreateSection({ name = app.t("section_presets") })
    local presetDropdown = tab:CreateDropdown({
        name = app.t("saved_presets"), options = presetOptions(), placeholder = app.t("no_presets"),
        callback = function(name) selectedPreset = bloodlineByName[name] and name or nil end,
    })
    tab:CreateButton({ name = app.t("apply_preset"), callback = function()
        if not selectedPreset then app.notify("error", "no_preset_selected"); return end
        apply({ "statz", "main", "kg1" }, "bloodline", bloodlineByName[selectedPreset], selectedPreset)
    end })
    tab:CreateButton({ name = app.t("save_current"), callback = function()
        local current = stat({ "statz", "main", "kg1" })
        local currentName
        if current then for name, id in pairs(bloodlineByName) do if id == current.Value then currentName = name; break end end end
        if not currentName then app.notify("error", "target_missing"); return end
        if table.find(app.settings.presets, currentName) then app.notify("error", "preset_duplicate"); return end
        table.insert(app.settings.presets, currentName); table.sort(app.settings.presets); app.save()
        presetDropdown:Refresh(app.settings.presets); app.notify("success", "preset_saved")
    end })
    tab:CreateButton({ name = app.t("clear_presets"), callback = function()
        selectedPreset = nil
        table.clear(app.settings.presets); app.save(); presetDropdown:Refresh({ app.t("no_presets") })
        app.notify("success", "presets_cleared")
    end })

    tab:CreateSection({ name = app.t("section_bloodline") })
    local bloodlineDropdown
    tab:CreateInput({
        name = app.t("search_bloodline"), placeholder = app.t("search_hint"), forgetState = true,
        callback = function(query)
            query = tostring(query):lower()
            local matches = {}
            for _, name in ipairs(bloodlineNames) do if name:lower():find(query, 1, true) then table.insert(matches, name) end end
            bloodlineDropdown:Refresh(#matches > 0 and matches or { app.t("no_matches") })
        end,
    })
    bloodlineDropdown = tab:CreateDropdown({
        name = app.t("bloodline_list"), options = bloodlineNames, value = selectedBloodline, forgetState = true,
        callback = function(name) if bloodlineByName[name] then selectedBloodline = name end end,
    })
    tab:CreateButton({ name = app.t("apply_bloodline"), callback = function() apply({ "statz", "main", "kg1" }, "bloodline", bloodlineByName[selectedBloodline], selectedBloodline) end })
    tab:CreateButton({ name = app.t("restore_bloodline"), callback = function() restore({ "statz", "main", "kg1" }, "bloodline") end })

    tab:CreateSection({ name = app.t("section_kenjutsu") })
    tab:CreateDropdown({
        name = app.t("kenjutsu_list"), options = kenjutsuNames, value = selectedKenjutsu, forgetState = true,
        callback = function(name) if kenjutsuByName[name] then selectedKenjutsu = name end end,
    })
    tab:CreateButton({ name = app.t("apply_kenjutsu"), callback = function() apply({ "statz", "breathingstyle" }, "kenjutsu", kenjutsuByName[selectedKenjutsu], selectedKenjutsu) end })
    tab:CreateButton({ name = app.t("restore_kenjutsu"), callback = function() restore({ "statz", "breathingstyle" }, "kenjutsu") end })
end
