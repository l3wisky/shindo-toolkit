return function(app, tab)
    local function saveSettings()
        if app.save() then
            return true
        end
        app.error("settings_save_failed", {
            reason = app.storage.lastError or "persistent storage is unavailable",
        })
        return false
    end

    local function copy(text, successKey)
        local copied = app.platform.copy(text)
        if copied then
            app.toast(successKey)
            return true
        end
        app.error("clipboard_failed")
        return false
    end

    tab:CreateSection({
        name = app.ui("section_settings"),
    })

    local languageIds = {
        [app.ui("english")] = "en",
        [app.ui("russian")] = "ru",
    }
    tab:CreateDropdown({
        name = app.ui("language"),
        options = { app.ui("english"), app.ui("russian") },
        value = if app.settings.language == "ru" then app.ui("russian") else app.ui("english"),
        forgetState = true,
        callback = function(choice)
            local language = languageIds[choice]
            if language and language ~= app.settings.language then
                app.settings.language = language
                saveSettings()
                app.window:SetLocale(language)
            end
        end,
    })

    local themeLabels = {}
    local themeIdsByLabel = {}
    local selectedThemeLabel = nil
    for _, theme in ipairs(app.themes) do
        local label = app.ui(theme.labelKey)
        table.insert(themeLabels, label)
        themeIdsByLabel[label] = theme.id
        if theme.id == app.settings.theme then
            selectedThemeLabel = label
        end
    end
    tab:CreateDropdown({
        name = app.ui("theme"),
        options = themeLabels,
        value = selectedThemeLabel,
        forgetState = true,
        callback = function(label)
            local theme = themeIdsByLabel[label]
            if theme and theme ~= app.settings.theme then
                app.settings.theme = theme
                saveSettings()
                app.window:ChangeTheme(theme)
            end
        end,
    })
    tab:CreateToggle({
        name = app.ui("notifications"),
        value = app.settings.notifications,
        forgetState = true,
        callback = function(value)
            app.settings.notifications = value
            saveSettings()
        end,
    })
    tab:CreateButton({
        name = app.ui("reset_settings"),
        callback = function()
            app.window:Popup({
                title = app.ui("reset_settings"),
                content = app.ui("reset_confirm"),
                options = {
                    {
                        text = app.ui("cancel"),
                        style = "neutral",
                    },
                    {
                        text = app.ui("reset"),
                        style = "danger",
                        callback = function()
                            if not app.storage.reset() then
                                app.error("settings_reset_failed")
                                return
                            end
                            task.defer(function()
                                app.rebuild()
                                app.toast("settings_reset")
                            end)
                        end,
                    },
                },
            })
        end,
    })

    tab:CreateButton({
        name = app.ui("github"),
        description = app.ui("github_description"),
        icon = app.icons.github,
        callback = function()
            if app.platform.capabilities.clipboard then
                copy(app.config.repositoryUrl, "github_copied")
                return
            end
            app.window:Popup({
                title = app.ui("github"),
                content = app.ui("github_fallback"),
                boxes = {
                    {
                        title = app.ui("github"),
                        description = app.config.repositoryUrl,
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
end
