-- Test script for some command API details.

local utils = require("mp.utils")

function join(sep, arr, count)
    local r = ""
    if count == nil then
        count = #arr
    end
    for i = 1, count do
        if i > 1 then
            r = r .. sep
        end
        r = r .. utils.to_string(arr[i])
    end
    return r
end

mp.observe_property("vo-configured", "bool", function(_, v)
    if v ~= true then
        return
    end

    print("async expand-text")
    mp.command_native_async({"expand-text", "hello ${path}!"},
        function(res, val, err)
            print("done async expand-text: " .. join(" ", {res, val, err}))
        end)

    -- make screenshot writing very slow
    mp.set_property("screenshot-format", "png")
    mp.set_property("screenshot-png-compression", "9")

    timer = mp.add_periodic_timer(0.1, function() print("I'm alive") end)
    timer:resume()

    print("Slow screenshot command...")
    res = mp.command_native({"screenshot"})
    print("done, res: " .. utils.to_string(res))

    print("Slow screenshot async command...")
    res = mp.command_native_async({"screenshot"}, function(res)
        print("done (async), res: " .. utils.to_string(res))
        timer:kill()
    end)
    print("done (sending), res: " .. utils.to_string(res))

    print("Broken screenshot async command...")
    mp.command_native_async({"screenshot-to-file", "/nonexistent/bogus.png"},
        function(res, val, err)
            print("done err scr.: " .. join(" ", {res, val, err}))
        end)

    mp.command_native_async({name = "subprocess", args = {"sh", "-c", "echo hi && sleep 10s"}, capture_stdout = true},
        function(res, val, err)
            print("done subprocess: " .. join(" ", {res, val, err}))
        end)

    local x = mp.command_native_async({name = "subprocess", args = {"sleep", "inf"}},
        function(res, val, err)
            print("done sleep inf subprocess: " .. join(" ", {res, val, err}))
        end)
    mp.add_timeout(15, function()
        print("aborting sleep inf subprocess after timeout")
        mp.abort_async_command(x)
    end)

    -- (assuming this "freezes")
    local y = mp.command_native_async({name = "sub-add", url = "-"},
        function(res, val, err)
            print("done sub-add stdin: " .. join(" ", {res, val, err}))
        end)
    mp.add_timeout(20, function()
        print("aborting sub-add stdin after timeout")
        mp.abort_async_command(y)
    end)


    mp.command_native_async({name = "subprocess", args = {"wc", "-c"},
                             stdin_data = "hello", capture_stdout = true},
        function(_, val)
            print("Should be '5': " .. val.stdout)
        end)
    -- blocking stdin by default
    mp.command_native_async({name = "subprocess", args = {"cat"},
                             capture_stdout = true},
        function(_, val)
            print("Should be 0: " .. #val.stdout)
        end)
    -- stdin + detached
    mp.command_native_async({name = "subprocess",
                             args = {"bash", "-c", "(sleep 5s ; cat)"},
                             stdin_data = "this should appear after 5s.\n",
                             detach = true},
        function(_, val)
            print("5s test: " .. val.status)
        end)

    -- This should get killed on script exit.
    mp.command_native_async({name = "subprocess", playback_only = false,
                             args = {"sleep", "inf"}}, function()end)

    -- Runs detached; should be killed on player exit (forces timeout)
    mp.command_native({_flags={"async"}, name = "subprocess",
                       playback_only = false, args = {"sleep", "inf"}})
end)

function freeze_test(playback_only)
    -- This "freezes" the script, should be killed via timeout.
    counter = counter and counter + 1 or 0
    print("freeze! " .. counter)
    local x = mp.command_native({name = "subprocess",
                                 playback_only = playback_only,
                                 args = {"sleep", "inf"}})
    print("done, killed=" .. utils.to_string(x.killed_by_us))
end

mp.register_event("shutdown", function()
    freeze_test(false)
end)

mp.register_event("idle", function()
    freeze_test(true)
end)
