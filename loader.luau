local HttpService = game:GetService("HttpService")
local artifactUrl = "https://github.com/l3wisky/shindo-toolkit/releases/latest/download/shindo-toolkit.luau"
local url = artifactUrl .. "?cache=" .. HttpService:GenerateGUID(false)

local downloaded, source = pcall(function()
    return game:HttpGet(url)
end)
if not downloaded then
    error("Shindo Toolkit failed to download the stable release: " .. tostring(source), 0)
end
if type(source) ~= "string" or source == "" then
    error("Shindo Toolkit received an empty stable release", 0)
end
if type(loadstring) ~= "function" then
    error("Shindo Toolkit requires loadstring support", 0)
end

local chunk, compileError = loadstring(source, "ShindoToolkit/release")
if not chunk then
    error("Shindo Toolkit failed to compile the stable release: " .. tostring(compileError), 0)
end

local executed, result = pcall(chunk)
if not executed then
    error("Shindo Toolkit failed to start the stable release: " .. tostring(result), 0)
end
return result
