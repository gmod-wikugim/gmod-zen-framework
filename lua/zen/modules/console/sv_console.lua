nt.RegisterChannel("zen.console.command")
nt.RegisterChannel("zen.console.server_console")
nt.RegisterChannel("zen.console.message")
nt.RegisterChannel("zen.console.console_status")
nt.RegisterChannel("zen.console.console_mode")

iperm.RegisterPermission("zen.console.server_console", iperm.flags.NO_TARGET, "Access to server console")
iperm.RegisterPermission("zen.console.server_log", iperm.flags.NO_TARGET, "Access to view server server after epoe")

function META.PLAYER:zen_console_log(...)
    local args = {...}
    nt.Send("zen.console.message", {"array:any"}, {args})
end

nt.Receive("zen.console.command", {"string"}, function(ply, str)
    local args = str:Split(" ")
    local cmd = args[1]
    table.remove(args, 1)

    ply:EmitSound("buttons/combine_button5.wav")

    local res, com = ihook.Run("zen.console.command", ply, cmd, args, str)
    if res == true or res == nil then
        ply:zen_console_log(com or "Successful ran")
    else
        ply:zen_console_log(com or "Command not ran!")
    end
end)

nt.Receive("zen.console.server_console", {"string"}, function(ply, str)
    local args = str:Split(" ")
    local cmd = args[1]
    table.remove(args, 1)

    ihook.Run("zen.console.server_console", ply, cmd, args, str)
end)

nt.Receive("zen.console.console_mode", {"uint8"}, function(ply, mode)
    if not ply:zen_HasPerm("zen.console.server_log") then ply:zen_console_log("no access") return end

    if epoe then
        if mode == 0 then
            epoe.DelSub(ply)
        elseif mode == 1 then
            epoe.DelSub(ply)
        elseif mode == 2 then
            epoe.AddSub(ply)
        end
    end

    nt.Send("zen.console.console_mode", {"player", "uint8"}, {ply, mode})
end)

nt.Receive("zen.console.console_status", {"bool"}, function(ply, status)
    if status then
        ply:EmitSound("buttons/combine_button1.wav")
    else
        ply:EmitSound("buttons/combine_button7.wav")
    end

    nt.Send("zen.console.console_status", {"player", "bool"}, {ply, status})
end)

ihook.Listen("zen.console.server_console", "check_rank", function(ply, cmd, args, argStr)
    if not ply:IsFullyAuthenticated() then ply:zen_console_log("no steam auth") return end
    if not ply:zen_HasPerm("zen.console.server_console") then ply:zen_console_log("no access") return end

    ply:EmitSound("buttons/combine_button2.wav")
    RunConsoleCommand(cmd, unpack(args))
end)