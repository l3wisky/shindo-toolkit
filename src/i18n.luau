local locales = {
    en = {
        window_title = "Shindo Toolkit", window_subtitle = "Small Shindo Life helper",
        tab_kg = "KG Changer", tab_rc = "RCGenkai", tab_misc = "Misc",
        section_presets = "Bloodline Presets", saved_presets = "Saved Bloodline Presets",
        no_presets = "No saved presets", no_preset_selected = "Select a saved Bloodline preset first.", save_current = "Add Current Bloodline", apply_preset = "Apply Selected Preset", clear_presets = "Clear Bloodline Presets",
        section_bloodline = "Bloodline", search_bloodline = "Search Bloodline", search_hint = "Type to filter...",
        bloodline_list = "Bloodline", apply_bloodline = "Apply Selected Bloodline", restore_bloodline = "Restore Original Bloodline",
        section_kenjutsu = "Kenjutsu", kenjutsu_list = "Kenjutsu", apply_kenjutsu = "Apply Selected Kenjutsu",
        restore_kenjutsu = "Restore Original Kenjutsu", section_rc = "RCGENKAI Override",
        rc_bloodline = "Bloodline for item1", apply_rc = "Apply Selected Override", restore_rc = "Restore Original item1",
        section_outfit = "Outfit", outfit_slot = "Outfit Slot", load_outfit = "Load Selected Outfit",
        section_teleport = "Teleports", home = "Home", rejoin = "Rejoin",
        section_date = "Date Rollback", rollback_date = "Rollback Date", restore_date = "Restore Original Date",
        rollback_rejoin = "Rollback Date + Rejoin", section_player = "Player Data", player = "Player",
        refresh_players = "Refresh Player List", player_info = "Selected Player", latest_ps = "PS code: {code}",
        game_days = "Game days: {days}", latest_ps_label = "PS Code", game_days_label = "Game Days", ps_unavailable = "No PS code is available to copy.", copy_ps = "Copy PS Code", unavailable = "Unavailable",
        section_settings = "Settings", language = "Language", english = "English", russian = "Русский", theme = "Rayfield Theme",
        theme_default = "Default", theme_cobalt = "Cobalt", theme_ember = "Ember", theme_amethyst = "Amethyst", theme_frost = "Frost", theme_rose = "Rose",
        notifications = "Notifications Enabled", reset_settings = "Reset Local Settings",
        success = "Success", error = "Error", original_unavailable = "Original value was not captured in this server.",
        target_missing = "Required game value is unavailable.", applied = "Applied: {value}", restored = "Restored: {value}",
        preset_saved = "Bloodline preset saved.", presets_cleared = "Bloodline presets cleared.",
        preset_duplicate = "That Bloodline is already saved.", filesystem_unavailable = "Filesystem support is unavailable; changes are kept in memory.",
        request_failed = "The game request failed: {reason}", copied = "PS code copied to clipboard.",
        clipboard_unavailable = "Clipboard support is unavailable.", settings_reset = "Local settings reset.", settings_reset_failed = "Local settings could not be reset on disk.",
        no_matches = "No matches", rejoining = "Rejoining...", date_saved = "Rollback applied and confirmed; original date saved.", rollback_unconfirmed = "The date rollback was not confirmed; rejoin was cancelled.",
    },
    ru = {
        window_title = "Shindo Toolkit", window_subtitle = "Небольшой помощник для Shindo Life",
        tab_kg = "Смена KG", tab_rc = "RCGenkai", tab_misc = "Разное",
        section_presets = "Пресеты родословных", saved_presets = "Сохранённые пресеты",
        no_presets = "Нет сохранённых пресетов", no_preset_selected = "Сначала выберите сохранённый пресет родословной.", save_current = "Добавить текущую родословную", apply_preset = "Применить выбранный пресет", clear_presets = "Очистить пресеты",
        section_bloodline = "Родословная", search_bloodline = "Поиск родословной", search_hint = "Введите текст для фильтра...",
        bloodline_list = "Родословная", apply_bloodline = "Применить выбранную родословную", restore_bloodline = "Вернуть исходную родословную",
        section_kenjutsu = "Кендзюцу", kenjutsu_list = "Кендзюцу", apply_kenjutsu = "Применить выбранное кендзюцу",
        restore_kenjutsu = "Вернуть исходное кендзюцу", section_rc = "Переопределение RCGENKAI",
        rc_bloodline = "Родословная для item1", apply_rc = "Применить переопределение", restore_rc = "Вернуть исходный item1",
        section_outfit = "Наряд", outfit_slot = "Слот наряда", load_outfit = "Загрузить выбранный наряд",
        section_teleport = "Телепорты", home = "Домой", rejoin = "Перезайти",
        section_date = "Откат даты", rollback_date = "Откатить дату", restore_date = "Вернуть исходную дату",
        rollback_rejoin = "Откатить дату и перезайти", section_player = "Данные игрока", player = "Игрок",
        refresh_players = "Обновить список игроков", player_info = "Выбранный игрок", latest_ps = "Код PS: {code}",
        game_days = "Игровых дней: {days}", latest_ps_label = "Код PS", game_days_label = "Игровые дни", ps_unavailable = "Нет доступного кода PS для копирования.", copy_ps = "Копировать код PS", unavailable = "Недоступно",
        section_settings = "Настройки", language = "Язык", english = "English", russian = "Русский", theme = "Тема Rayfield",
        theme_default = "Default", theme_cobalt = "Cobalt", theme_ember = "Ember", theme_amethyst = "Amethyst", theme_frost = "Frost", theme_rose = "Rose",
        notifications = "Уведомления включены", reset_settings = "Сбросить локальные настройки",
        success = "Готово", error = "Ошибка", original_unavailable = "Исходное значение не было сохранено на этом сервере.",
        target_missing = "Необходимое игровое значение недоступно.", applied = "Применено: {value}", restored = "Восстановлено: {value}",
        preset_saved = "Пресет родословной сохранён.", presets_cleared = "Пресеты родословных очищены.",
        preset_duplicate = "Эта родословная уже сохранена.", filesystem_unavailable = "Файловая система недоступна; изменения хранятся в памяти.",
        request_failed = "Игровой запрос завершился ошибкой: {reason}", copied = "Код PS скопирован.",
        clipboard_unavailable = "Буфер обмена недоступен.", settings_reset = "Локальные настройки сброшены.", settings_reset_failed = "Не удалось сбросить локальные настройки на диске.",
        no_matches = "Нет совпадений", rejoining = "Переподключение...", date_saved = "Откат применён и подтверждён; исходная дата сохранена.", rollback_unconfirmed = "Откат даты не подтверждён; переподключение отменено.",
    },
}

local function translate(language, key, values)
    local text = assert((locales[language] or locales.en)[key] or locales.en[key], "missing translation: " .. tostring(key))
    if values then text = text:gsub("{([%w_]+)}", function(name) return tostring(values[name] or "{" .. name .. "}") end) end
    return text
end

return { locales = locales, translate = translate }
