return function(development)
    local storageFolder = if development then "ShindoToolkitDev" else "ShindoToolkit"

    local platform = {
        storageFolder = storageFolder,
        capabilities = {
            clipboard = type(setclipboard) == "function",
            filesystem = type(isfile) == "function"
                and type(readfile) == "function"
                and type(writefile) == "function",
        },
    }

    function platform.environment()
        if type(getgenv) == "function" then
            local succeeded, environment = pcall(getgenv)
            if succeeded and type(environment) == "table" then
                return environment
            end
        end
        -- `_G` is the only portable fallback when an executor does not expose
        -- `getgenv`; access is deliberately confined to this adapter.
        -- selene: allow(global_usage)
        return _G
    end

    function platform.fileExists(path)
        if type(isfile) ~= "function" then
            return false
        end
        local succeeded, exists = pcall(isfile, path)
        return succeeded and exists == true
    end

    function platform.readText(path)
        if type(readfile) ~= "function" or not platform.fileExists(path) then
            return nil, "file is unavailable"
        end
        local succeeded, contents = pcall(readfile, path)
        if not succeeded or type(contents) ~= "string" then
            return nil, tostring(contents)
        end
        return contents, nil
    end

    local function ensureStorageFolder()
        if type(isfolder) ~= "function" then
            return true
        end
        local checked, exists = pcall(isfolder, storageFolder)
        if checked and exists then
            return true
        end
        if type(makefolder) ~= "function" then
            return false, "makefolder is unavailable"
        end
        local created, reason = pcall(makefolder, storageFolder)
        if not created then
            return false, tostring(reason)
        end
        return true, nil
    end

    function platform.writeText(path, contents)
        if type(writefile) ~= "function" then
            return false, "writefile is unavailable"
        end
        local folderReady, folderError = ensureStorageFolder()
        if not folderReady then
            return false, folderError
        end
        local succeeded, reason = pcall(writefile, path, contents)
        if not succeeded then
            return false, tostring(reason)
        end
        return true, nil
    end

    function platform.deleteFile(path)
        if not platform.fileExists(path) then
            return true, nil
        end
        if type(delfile) ~= "function" then
            return false, "delfile is unavailable"
        end
        local succeeded, reason = pcall(delfile, path)
        if not succeeded then
            return false, tostring(reason)
        end
        if platform.fileExists(path) then
            return false, "the file still exists after deletion"
        end
        return true, nil
    end

    function platform.copy(text)
        if type(setclipboard) ~= "function" then
            return false, "setclipboard is unavailable"
        end
        local succeeded, reason = pcall(setclipboard, text)
        if not succeeded then
            return false, tostring(reason)
        end
        return true, nil
    end

    return platform
end
