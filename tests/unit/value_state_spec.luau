local createValueState = require("../../src/value_state")
local node = require("../support/node")

return function(check)
    local messages = {}
    local app = {
        originals = {},
        error = function(key)
            table.insert(messages, "error:" .. key)
        end,
        toast = function(key)
            table.insert(messages, "toast:" .. key)
        end,
        missing = function(key, path)
            table.insert(messages, "missing:" .. key .. ":" .. path)
            return false
        end,
    }

    local target = node("original")
    local root = node(nil, { nested = node(nil, { target = target }) })
    local values = createValueState(app)

    check(
        values.apply(root, { "nested", "target" }, "sample", "first", "First"),
        "apply should succeed"
    )
    check(target.Value == "first", "apply should write the selected value")
    check(app.originals.sample == "original", "apply should capture the original once")
    check(
        values.applyTarget(target, "sample", "second", "Second", "Root.nested.target"),
        "applyTarget should succeed"
    )
    check(app.originals.sample == "original", "second apply must not replace the original")
    check(values.restoreTarget(target, "sample", "Root.nested.target"), "restoreTarget should succeed")
    check(target.Value == "original", "restore should write the captured original")
    check(
        not values.apply(root, { "missing" }, "missing", "value", "Value", "Root.missing"),
        "missing target should fail"
    )
    check(
        messages[#messages] == "missing:target_missing:Root.missing",
        "missing target should report its exact path"
    )

    check(
        not values.restoreTarget(target, "unknown", "Root.nested.target"),
        "restore without an original should fail"
    )
    check(messages[#messages] == "error:original_unavailable", "missing original should report an error")
end
