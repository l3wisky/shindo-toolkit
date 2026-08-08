local createDateController = require("../../src/features/misc/date_controller")

return function(check)
    local band = {
        Value = "original",
    }
    local bandPresent = true
    local autoConfirm = true
    local fireResult = true
    local rejoinResult = true
    local rejoinCalls = 0
    local now = 0
    local messages = {}

    local client = {
        paths = {
            dateBand = "Players.LocalPlayer.statz.character.band",
        },
        getDateBand = function()
            return if bandPresent then band else nil
        end,
        fireStartEvent = function(command, value)
            check(command == "band", "date controller should use the band command")
            if not fireResult then
                return false
            end
            if autoConfirm then
                band.Value = value
            end
            return true
        end,
        rejoin = function()
            rejoinCalls += 1
            return rejoinResult
        end,
    }
    local app = {
        game = client,
        originals = {},
        config = {
            timeouts = {
                dateConfirmation = 0.2,
                datePollInterval = 0.05,
            },
            game = {
                rollbackBand = "rollback",
            },
        },
        missing = function(key, path)
            table.insert(messages, "missing:" .. key .. ":" .. path)
            return false
        end,
        error = function(key)
            table.insert(messages, "error:" .. key)
        end,
        toast = function(key)
            table.insert(messages, "toast:" .. key)
        end,
    }

    local controller = createDateController(app, {
        client = client,
        clock = function()
            return now
        end,
        wait = function(duration)
            now += duration
        end,
    })

    check(controller.rollback(), "rollback should succeed after server confirmation")
    check(band.Value == "rollback", "rollback should apply the configured band")
    check(app.originals.date == "original", "rollback should capture the original date")
    check(messages[#messages] == "toast:rollback_applied", "rollback should notify the user")

    band.Value = "later"
    check(controller.rollback(), "repeated rollback should still succeed")
    check(app.originals.date == "original", "repeated rollback must preserve the first original")

    check(controller.restore(), "restore should succeed when an original exists")
    check(band.Value == "original", "restore should apply the captured original")
    check(messages[#messages] == "toast:original_date_restored", "restore should notify the user")

    check(controller.rollbackAndRejoin(), "rollback-and-rejoin should compose both operations")
    check(rejoinCalls == 1, "rollback-and-rejoin should rejoin exactly once")

    local nestedResult = nil
    check(
        controller.run(function()
            nestedResult = controller.run(function()
                return true
            end)
            return true
        end),
        "outer operation should finish"
    )
    check(nestedResult == false, "concurrent date operations should be rejected")
    check(messages[#messages] == "error:operation_busy", "busy operations should explain the rejection")

    check(
        not controller.run(function()
            error("operation exploded")
        end),
        "operation exceptions should fail safely"
    )
    check(not controller.isBusy(), "date mutex must be released after an exception")
    check(
        controller.run(function()
            return true
        end),
        "date controller should remain usable after an exception"
    )

    bandPresent = false
    check(not controller.rollback(), "missing date band should fail")
    check(
        messages[#messages] == "missing:target_missing:Players.LocalPlayer.statz.character.band",
        "missing date band should report its canonical path"
    )
    bandPresent = true

    fireResult = false
    check(not controller.rollback(), "failed remote calls should stop rollback")
    fireResult = true

    autoConfirm = false
    band.Value = "unconfirmed"
    now = 0
    check(not controller.rollback(), "unconfirmed server state should time out")
    check(messages[#messages] == "error:date_change_unconfirmed", "timeout should be reported")
    check(now >= 0.2, "confirmation timeout should use the configured deadline")
    autoConfirm = true

    rejoinResult = false
    check(not controller.rollbackAndRejoin(), "rejoin failure should fail the combined operation")
end
