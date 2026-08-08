local factories = {
    ["src/config.luau"] = function()
        return require("../src/config")
    end,
    ["src/data.luau"] = function()
        return require("../src/data")
    end,
    ["src/i18n.luau"] = function()
        return require("../src/i18n")
    end,
    ["src/platform.luau"] = function()
        return require("../src/platform")
    end,
    ["src/storage.luau"] = function()
        return require("../src/storage")
    end,
    ["src/value_state.luau"] = function()
        return require("../src/value_state")
    end,
    ["src/runtime/rayfield.luau"] = function()
        return require("../src/runtime/rayfield")
    end,
    ["vendor/rayfield-gen2/bundled.luau"] = function()
        return require("../vendor/rayfield-gen2/bundled")
    end,
    ["src/game/client.luau"] = function()
        return require("../src/game/client")
    end,
    ["src/features/kg_changer.luau"] = function()
        return require("../src/features/kg_changer")
    end,
    ["src/features/rcgenkai.luau"] = function()
        return require("../src/features/rcgenkai")
    end,
    ["src/features/misc/init.luau"] = function()
        return require("../src/features/misc/init")
    end,
    ["src/features/misc/outfit.luau"] = function()
        return require("../src/features/misc/outfit")
    end,
    ["src/features/misc/teleport.luau"] = function()
        return require("../src/features/misc/teleport")
    end,
    ["src/features/misc/date.luau"] = function()
        return require("../src/features/misc/date")
    end,
    ["src/features/misc/date_controller.luau"] = function()
        return require("../src/features/misc/date_controller")
    end,
    ["src/features/misc/player_info.luau"] = function()
        return require("../src/features/misc/player_info")
    end,
    ["src/features/misc/settings.luau"] = function()
        return require("../src/features/misc/settings")
    end,
}

local cache = {}
local function loadModule(path)
    local cached = cache[path]
    if cached ~= nil then
        return cached
    end

    local factory = factories[path]
    assert(factory ~= nil, "missing bundled module: " .. tostring(path))
    local module = factory()
    cache[path] = module
    return module
end

return require("../src/init")({
    load = loadModule,
    development = false,
})
