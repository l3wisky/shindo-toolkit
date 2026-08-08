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

    check(values.apply(root, { "nested", "target" }, "sample", "first", "First"), "apply should succeed")
    check(target.Value == "first", "apply should write the selected value")
    check(app.originals.sample.target == target, "apply should associate the original with its target")
    check(app.originals.sample.value == "original", "apply should capture the original value")
    check(
        values.applyTarget(target, "sample", "second", "Second", "Root.nested.target"),
        "applyTarget should succeed"
    )
    check(app.originals.sample.value == "original", "second apply must not replace the original")
    check(values.restoreTarget(target, "sample", "Root.nested.target"), "restoreTarget should succeed")
    check(target.Value == "original", "restore should write the captured original")

    local replacement = node("replacement-original")
    check(
        not values.restoreTarget(replacement, "sample", "Root.nested.target"),
        "restore must reject an original captured from a replaced target"
    )
    check(replacement.Value == "replacement-original", "stale restore must not mutate the replacement target")
    check(
        values.applyTarget(replacement, "sample", "replacement-value", "Replacement", "Root.nested.target"),
        "apply should capture a fresh original for a replacement target"
    )
    check(app.originals.sample.target == replacement, "replacement capture should update the target identity")
    check(
        app.originals.sample.value == "replacement-original",
        "replacement capture should store its own baseline"
    )
    check(
        values.restoreTarget(replacement, "sample", "Root.nested.target"),
        "replacement restore should succeed"
    )
    check(replacement.Value == "replacement-original", "replacement restore should use its own baseline")
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
