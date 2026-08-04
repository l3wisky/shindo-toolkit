local repository = "https://raw.githubusercontent.com/l3wisky/shindo-toolkit/"
local branch = "dev"
local function load(path)
    local source = game:HttpGet(repository .. branch .. "/" .. path)
    local chunk, err = loadstring(source, "ShindoToolkit/" .. path)
    if not chunk then error(err) end
    return chunk()
end
return load("src/init.luau")({ load = load, branch = branch })
