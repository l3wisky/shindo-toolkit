local modules = {
    ["src/config.luau"] = require("../src/config"),
    ["src/data.luau"] = require("../src/data"),
    ["src/i18n.luau"] = require("../src/i18n"),
    ["src/platform.luau"] = require("../src/platform"),
    ["src/storage.luau"] = require("../src/storage"),
    ["src/value_state.luau"] = require("../src/value_state"),
    ["src/runtime/rayfield.luau"] = require("../src/runtime/rayfield"),
    ["src/game/client.luau"] = require("../src/game/client"),
    ["src/features/kg_changer.luau"] = require("../src/features/kg_changer"),
    ["src/features/rcgenkai.luau"] = require("../src/features/rcgenkai"),
    ["src/features/misc/init.luau"] = require("../src/features/misc/init"),
    ["src/features/misc/outfit.luau"] = require("../src/features/misc/outfit"),
    ["src/features/misc/teleport.luau"] = require("../src/features/misc/teleport"),
    ["src/features/misc/date.luau"] = require("../src/features/misc/date"),
    ["src/features/misc/date_controller.luau"] = require("../src/features/misc/date_controller"),
    ["src/features/misc/player_info.luau"] = require("../src/features/misc/player_info"),
    ["src/features/misc/settings.luau"] = require("../src/features/misc/settings"),
}

local function loadModule(path)
    local module = modules[path]
    assert(module ~= nil, "missing bundled module: " .. tostring(path))
    return module
end

return require("../src/init")({
    load = loadModule,
    development = false,
})
