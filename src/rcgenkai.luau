return function(app)
    local tab = app.window:CreateTab({ name = app.t("tab_rc") })
    local names, ids = {}, {}
    for _, item in ipairs(app.data.bloodlines) do table.insert(names, item.name); ids[item.name] = item.id end
    table.sort(names)
    local selected = names[1]
    local function item1()
        local shop = workspace:FindFirstChild("RCGENKAI")
        return shop and shop:FindFirstChild("item1")
    end
    tab:CreateSection({ name = app.t("section_rc") })
    tab:CreateDropdown({
        name = app.t("rc_bloodline"), options = names, value = selected, forgetState = true,
        callback = function(name) if ids[name] then selected = name end end,
    })
    tab:CreateButton({ name = app.t("apply_rc"), callback = function()
        local value = item1()
        if not value then app.notify("error", "target_missing"); return end
        if app.originals.rcgenkai == nil then app.originals.rcgenkai = value.Value end
        value.Value = ids[selected]; app.notify("success", "applied", { value = selected })
    end })
    tab:CreateButton({ name = app.t("restore_rc"), callback = function()
        local value, original = item1(), app.originals.rcgenkai
        if not value or original == nil then app.notify("error", "original_unavailable"); return end
        value.Value = original; app.notify("success", "restored", { value = original })
    end })
end
