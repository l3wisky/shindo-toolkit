local HttpService = game:GetService("HttpService")
local repository = "https://raw.githubusercontent.com/l3wisky/shindo-toolkit/"
local runtimeRef = "dev"
local cacheToken = HttpService:GenerateGUID(false)

local function loadModule(path)
    local url = repository .. runtimeRef .. "/" .. path .. "?cache=" .. cacheToken
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
    development = true,
})
