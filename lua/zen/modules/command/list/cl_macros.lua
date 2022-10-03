local icmd = zen.Import("command")

local alias_help = [[
Example:
    alias godmode sv "lua_run_sv me:GodEnable()"
    alias hunger zen "hunger ^ 100"]]

icmd.Register("alias", function(QCMD, who, cmd, args, tags, mode)
    if !args[1] or tags["help"] then
        return alias_help
    end

    do return false, "Now alias command in dev" end

    return true
end, {
    {type = "string_id", name = "alias"},
    {type = "int8", name = "mode"},
    {type = "string_id", name = "command"}
}, {
    help = alias_help
})

icmd.Register("whoam", function(QCMD, who, cmd, args, tags, mode)

    return {"You are is: ", LocalPlayer():SteamID64()}
end, {}, {})