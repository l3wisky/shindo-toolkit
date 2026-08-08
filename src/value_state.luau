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

    local function captureOriginal(target, originalKey, value)
        local original = app.originals[originalKey]
        if type(original) ~= "table" or original.target ~= target then
            original = {
                target = target,
                value = value,
            }
            app.originals[originalKey] = original
        end
    end

    function valueState.applyTarget(target, originalKey, value, displayValue, targetPath)
        if not target then
            return app.missing("target_missing", targetPath)
        end

        local current, readError = read(target)
        if readError then
            app.error("value_read_failed", { reason = readError })
            return false
        end
        captureOriginal(target, originalKey, current)
        if not write(target, value) then
            return false
        end
        app.toast("applied", { value = displayValue })
        return true
    end

    function valueState.restoreTarget(target, originalKey, targetPath)
        if not target then
            return app.missing("target_missing", targetPath)
        end

        local original = app.originals[originalKey]
        if type(original) ~= "table" or original.target ~= target then
            app.error("original_unavailable")
            return false
        end
        if not write(target, original.value) then
            return false
        end
        app.toast("restored", { value = original.value })
        return true
    end

    function valueState.apply(root, path, originalKey, value, displayValue, targetPath)
        local label = targetPath or table.concat(path, ".")
        return valueState.applyTarget(find(root, path), originalKey, value, displayValue, label)
    end

    function valueState.restore(root, path, originalKey, targetPath)
        local label = targetPath or table.concat(path, ".")
        return valueState.restoreTarget(find(root, path), originalKey, label)
    end

    valueState.find = find
    return valueState
end
