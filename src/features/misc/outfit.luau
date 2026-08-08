return function(app, tab)
    local selectedSlot = 1

    tab:CreateSection({
        name = app.ui("section_outfit"),
    })
    tab:CreateDropdown({
        name = app.ui("outfit_slot"),
        options = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" },
        value = tostring(selectedSlot),
        forgetState = true,
        callback = function(value)
            selectedSlot = tonumber(value) or 1
        end,
    })
    tab:CreateButton({
        name = app.ui("load_outfit"),
        callback = function()
            app.game.fireStartEvent("loadoutfit", selectedSlot)
        end,
    })
end
