local modules = {
    ["src/config.luau"] = require("../src/config"),
    ["src/data.luau"] = require("../src/data"),
    ["src/i18n.luau"] = require("../src/i18n"),
    ["src/kg_changer.luau"] = require("../src/kg_changer"),
    ["src/misc.luau"] = require("../src/misc"),
    ["src/platform.luau"] = require("../src/platform"),
    ["src/rcgenkai.luau"] = require("../src/rcgenkai"),
    ["src/storage.luau"] = require("../src/storage"),
    ["src/value_state.luau"] = require("../src/value_state"),
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
