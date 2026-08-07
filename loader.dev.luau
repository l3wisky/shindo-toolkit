local HttpService = game:GetService("HttpService")
local repository = "https://raw.githubusercontent.com/l3wisky/shindo-toolkit/"
local runtimeRef = "dev"
local cacheToken = HttpService:GenerateGUID(false)
local moduleCache = {}

local function loadModule(path)
    if moduleCache[path] ~= nil then
        return moduleCache[path]
    end

    local url = repository .. runtimeRef .. "/" .. path .. "?cache=" .. cacheToken
    local downloaded, source = pcall(function()
        return game:HttpGet(url)
    end)
    if not downloaded then
        error("Shindo Toolkit failed to download " .. path .. ": " .. tostring(source), 0)
    end
    if type(source) ~= "string" or source == "" then
        error("Shindo Toolkit received an empty module: " .. path, 0)
    end
    if type(loadstring) ~= "function" then
        error("Shindo Toolkit requires loadstring support", 0)
    end

    local chunk, compileError = loadstring(source, "ShindoToolkit/" .. path)
    if not chunk then
        error("Shindo Toolkit failed to compile " .. path .. ": " .. tostring(compileError), 0)
    end

    local executed, result = pcall(chunk)
    if not executed then
        error("Shindo Toolkit failed to execute " .. path .. ": " .. tostring(result), 0)
    end
    moduleCache[path] = result
    return result
end

return loadModule("src/init.luau")({
    load = loadModule,
    development = true,
})
