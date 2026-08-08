return function(app, dependencies)
    dependencies = dependencies or {}

    local client = dependencies.client or app.game
    local clock = dependencies.clock or os.clock
    local wait = dependencies.wait or task.wait
    local busy = false
    local controller = {}

    local function readValue(target)
        local succeeded, value = pcall(function()
            return target.Value
        end)
        if not succeeded then
            app.error("value_read_failed", { reason = tostring(value) })
            return nil, false
        end
        return value, true
    end

    local function captureDate()
        local band = client.getDateBand()
        if not band then
            app.missing("target_missing", client.paths.dateBand)
            return nil
        end
        if app.originals.date == nil then
            local original, readSuccessfully = readValue(band)
            if not readSuccessfully then
                return nil
            end
            app.originals.date = original
        end
        return band
    end

    local function waitForBandValue(band, expectedValue)
        local deadline = clock() + app.config.timeouts.dateConfirmation
        repeat
            local readSuccessfully, current = pcall(function()
                return band.Value
            end)
            if not readSuccessfully then
                return false
            end
            if current == expectedValue then
                return true
            end
            wait(app.config.timeouts.datePollInterval)
        until clock() >= deadline
        return false
    end

    local function applyDate(band, value, successKey)
        if not client.fireStartEvent("band", value) then
            return false
        end
        if not waitForBandValue(band, value) then
            app.error("date_change_unconfirmed")
            return false
        end
        if successKey then
            app.toast(successKey)
        end
        return true
    end

    function controller.run(callback)
        if busy then
            app.error("operation_busy")
            return false
        end

        busy = true
        local succeeded, result = xpcall(callback, function(reason)
            return tostring(reason)
        end)
        busy = false

        if not succeeded then
            app.error("operation_failed", { reason = result })
            return false
        end
        return result ~= false
    end

    function controller.rollback()
        return controller.run(function()
            local band = captureDate()
            if not band then
                return false
            end
            return applyDate(band, app.config.game.rollbackBand, "rollback_applied")
        end)
    end

    function controller.restore()
        return controller.run(function()
            if app.originals.date == nil then
                app.error("original_unavailable")
                return false
            end
            local band = client.getDateBand()
            if not band then
                return app.missing("target_missing", client.paths.dateBand)
            end
            return applyDate(band, app.originals.date, "original_date_restored")
        end)
    end

    function controller.rollbackAndRejoin()
        return controller.run(function()
            local band = captureDate()
            if not band then
                return false
            end
            if not applyDate(band, app.config.game.rollbackBand) then
                return false
            end
            return client.rejoin()
        end)
    end

    function controller.isBusy()
        return busy
    end

    return controller
end
