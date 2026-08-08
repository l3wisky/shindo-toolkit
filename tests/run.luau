local specs = {
    { name = "config", run = require("./unit/config_spec") },
    { name = "data", run = require("./unit/data_spec") },
    { name = "i18n", run = require("./unit/i18n_spec") },
    { name = "value_state", run = require("./unit/value_state_spec") },
    { name = "storage", run = require("./unit/storage_spec") },
    { name = "game_client", run = require("./unit/game_client_spec") },
    { name = "date_controller", run = require("./unit/date_controller_spec") },
    { name = "rayfield_runtime", run = require("./unit/rayfield_runtime_spec") },
}

local checks = 0
local function check(condition, message)
    checks += 1
    assert(condition, message)
end

for _, spec in ipairs(specs) do
    local before = checks
    spec.run(check)
    print(string.format("%s: %d checks passed", spec.name, checks - before))
end

print(string.format("unit: %d checks passed", checks))
