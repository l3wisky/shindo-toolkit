local validateRayfield = require("../../src/runtime/rayfield")

local config = {
    version = "1.1.0",
}

local function failure(create)
    local succeeded, reason = pcall(create)
    return succeeded, tostring(reason)
end

return function(check)
    local runtime = {
        CreateWindow = function() end,
    }
    local rayfield = validateRayfield(runtime, config)
    check(rayfield == runtime, "valid vendored Rayfield runtime should be returned")

    local validated, validationReason = failure(function()
        validateRayfield({}, config)
    end)
    check(not validated, "invalid Rayfield exports should be rejected")
    check(
        validationReason:match("Vendored Rayfield Gen2 1.1.0 returned an invalid runtime") ~= nil,
        "invalid vendor error should identify the pinned version"
    )
end
