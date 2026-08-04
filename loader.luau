local repository = "https://raw.githubusercontent.com/l3wisky/shindo-toolkit/"
local branch = "main"

local function loadModule(path)
    local url = repository .. branch .. "/" .. path
    local downloaded, source = pcall(function()
        return game:HttpGet(url)
    end)
    if not downloaded then
        error("Shindo Toolkit failed to download " .. path .. ": " .. tostring(source))
    end

    local chunk, compileError = loadstring(source, "ShindoToolkit/" .. path)
    if not chunk then
        error("Shindo Toolkit failed to compile " .. path .. ": " .. tostring(compileError))
    end
    return chunk()
end

return loadModule("src/init.luau")({
    load = loadModule,
    branch = branch,
})
