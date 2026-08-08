return function(platform, config)
    local source, downloadError = platform.httpGet(config.url)
    if not source then
        error(
            string.format("Rayfield Gen2 %s download failed: %s", config.version, tostring(downloadError)),
            0
        )
    end

    local chunk, compileError = platform.compile(source, "ShindoToolkit/RayfieldGen2@" .. config.version)
    if not chunk then
        error(
            string.format("Rayfield Gen2 %s compile failed: %s", config.version, tostring(compileError)),
            0
        )
    end

    local started, rayfield = pcall(chunk)
    if not started then
        error(string.format("Rayfield Gen2 %s startup failed: %s", config.version, tostring(rayfield)), 0)
    end
    if type(rayfield) ~= "table" or type(rayfield.CreateWindow) ~= "function" then
        error("Rayfield Gen2 returned an invalid runtime", 0)
    end

    return rayfield
end
