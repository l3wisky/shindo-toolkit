--!strict

type Config = {
    version: string,
}

export type RayfieldRuntime = {
    CreateWindow: (RayfieldRuntime, { [string]: any }) -> any,
}

return function(rayfield: any, config: Config): RayfieldRuntime
    if type(rayfield) ~= "table" or type(rayfield.CreateWindow) ~= "function" then
        error(string.format("Vendored Rayfield Gen2 %s returned an invalid runtime", config.version), 0)
    end
    return rayfield :: RayfieldRuntime
end
