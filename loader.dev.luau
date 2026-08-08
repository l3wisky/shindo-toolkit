local HttpService = game:GetService("HttpService")
local repositoryName = "l3wisky/shindo-toolkit"
local rawRepository = "https://raw.githubusercontent.com/" .. repositoryName .. "/"
local runtimeBranch = "dev"
local cacheToken = HttpService:GenerateGUID(false)
local moduleCache = {}

local function resolveRuntimeRef()
    local url = "https://api.github.com/repos/"
        .. repositoryName
        .. "/commits/"
        .. runtimeBranch
        .. "?cache="
        .. cacheToken
    local downloaded, response = pcall(function()
        return game:HttpGet(url)
    end)
    if not downloaded then
        error("Shindo Toolkit failed to resolve the dev commit: " .. tostring(response), 0)
    end

    local decodedSuccessfully, metadata = pcall(function()
        return HttpService:JSONDecode(response)
    end)
    local commit = if decodedSuccessfully and type(metadata) == "table" then metadata.sha else nil
    if type(commit) ~= "string" or not string.match(commit, "^[0-9a-fA-F]+$") or #commit ~= 40 then
        error("Shindo Toolkit received an invalid dev commit from GitHub", 0)
    end
    return commit
end

local runtimeRef = resolveRuntimeRef()

local function loadModule(path)
    if moduleCache[path] ~= nil then
        return moduleCache[path]
    end

    local url = rawRepository .. runtimeRef .. "/" .. path
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
