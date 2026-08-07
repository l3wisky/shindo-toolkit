return function(app)
    local valueState = {}

    local function find(root, path)
        local current = root
        for _, name in ipairs(path) do
            if not current or type(current.FindFirstChild) ~= "function" then
                return nil
            end
            current = current:FindFirstChild(name)
        end
        return current
    end

    local function read(target)
        local succeeded, value = pcall(function()
            return target.Value
        end)
        if not succeeded then
            return nil, tostring(value)
        end
        return value, nil
    end

    local function write(target, value)
        local succeeded, reason = pcall(function()
            target.Value = value
        end)
        if not succeeded then
            app.error("value_write_failed", { reason = tostring(reason) })
            return false
        end
        return true
    end

    local function missing(path, targetPath)
        local label = targetPath or table.concat(path, ".")
        return app.missing("target_missing", label)
    end

    function valueState.apply(root, path, originalKey, value, displayValue, targetPath)
        local target = find(root, path)
        if not target then
            return missing(path, targetPath)
        end

        local current, readError = read(target)
        if readError then
            app.error("value_read_failed", { reason = readError })
            return false
        end
        if app.originals[originalKey] == nil then
            app.originals[originalKey] = current
        end
        if not write(target, value) then
            return false
        end
        app.toast("applied", { value = displayValue })
        return true
    end

    function valueState.restore(root, path, originalKey, targetPath)
        local target = find(root, path)
        if not target then
            return missing(path, targetPath)
        end
        local original = app.originals[originalKey]
        if original == nil then
            app.error("original_unavailable")
            return false
        end
        if not write(target, original) then
            return false
        end
        app.toast("restored", { value = original })
        return true
    end

    valueState.find = find
    return valueState
end
