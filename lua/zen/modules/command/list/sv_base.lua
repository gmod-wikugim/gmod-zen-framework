local icmd = zen.Import("command")

icmd.Register("auth", function(who, cmd, args, tags, mode)
    if who:zen_GetVar("auth") then
        return false, "You already authed"
    end

    who:zen_SetVar("auth", true)

    return true
end, {}, {
    perm = "public",
    help = "auth - Authorize access"
})

icmd.Register("unauth", function(who)
    if not who:zen_GetVar("auth") then
        return false, "You already unauthed"
    end

    who:zen_SetVar("auth", false)

    return true, "Sucess UnAuth"
end, {}, {
    perm = "public",
    help = "unauth - Unauthorize access"
})