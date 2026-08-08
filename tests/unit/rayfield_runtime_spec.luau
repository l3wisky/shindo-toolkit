local createRayfield = require("../../src/runtime/rayfield")

local config = {
    version = "1.1.0",
    url = "https://example.invalid/rayfield.luau",
}

local function failure(create)
    local succeeded, reason = pcall(create)
    return succeeded, tostring(reason)
end

return function(check)
    local platform = {
        httpGet = function(url)
            check(url == config.url, "Rayfield runtime should request the pinned URL")
            return "return {}", nil
        end,
        compile = function(source, chunkName)
            check(source == "return {}", "Rayfield runtime should compile the downloaded source")
            check(
                chunkName == "ShindoToolkit/RayfieldGen2@1.1.0",
                "Rayfield runtime should use a diagnostic chunk name"
            )
            return function()
                return {
                    CreateWindow = function() end,
                }
            end, nil
        end,
    }

    local rayfield = createRayfield(platform, config)
    check(type(rayfield.CreateWindow) == "function", "valid Rayfield runtime should be returned")

    platform.httpGet = function()
        return nil, "network unavailable"
    end
    local downloaded, downloadReason = failure(function()
        createRayfield(platform, config)
    end)
    check(not downloaded, "download failures should abort startup")
    check(downloadReason:match("download failed"), "download failure should include its stage")

    platform.httpGet = function()
        return "invalid", nil
    end
    platform.compile = function()
        return nil, "syntax error"
    end
    local compiled, compileReason = failure(function()
        createRayfield(platform, config)
    end)
    check(not compiled, "compile failures should abort startup")
    check(compileReason:match("compile failed"), "compile failure should include its stage")

    platform.compile = function()
        return function()
            error("startup exploded")
        end, nil
    end
    local started, startupReason = failure(function()
        createRayfield(platform, config)
    end)
    check(not started, "Rayfield startup exceptions should be wrapped")
    check(startupReason:match("startup failed"), "startup failure should include its stage")

    platform.compile = function()
        return function()
            return {}
        end, nil
    end
    local validated, validationReason = failure(function()
        createRayfield(platform, config)
    end)
    check(not validated, "invalid Rayfield exports should be rejected")
    check(
        validationReason:match("invalid runtime") ~= nil,
        "invalid Rayfield export should have a precise error"
    )
end
