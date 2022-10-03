local icmd = zen.Import("command")

icmd.Register("auth", function(QCMD, who)
    if who:zen_GetVar("auth") then
        return "You already authed"
    end

    who:zen_SetVar("auth", true)

    return true
end, {}, {
    perm = "public",
    help = "auth - Authorize access"
})

icmd.Register("unauth", function(QCMD, who)
    if not who:zen_GetVar("auth") then
        return "You already unauthed"
    end

    who:zen_SetVar("auth", false)

    return true, "Successful unauth"
end, {}, {
    perm = "public",
    help = "unauth - Unauthorize access"
})

icmd.Register("sudo", function(QCMD, who, cmd, args, tags)
    game.ConsoleCommand(args[1] .. "\n")
end, {
    {type="string", name="command"}
}, {
    perm = "console.command",
    help = "Run Command on server console"
})