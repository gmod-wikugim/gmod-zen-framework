local icmd = zen.Import("command")

local alias_help = [[
Example:
    alias godmode sv "lua_run_sv me:GodEnable()"
    alias hunger zen "hunger ^ 100"]]

icmd.Register("alias", function(who, cmd, args, tags, mode)
    if !args[1] or tags["help"] then
        return alias_help
    end

    return true
end, {
    {type = "string", name = "alias"},
    {type = "mode", name = "mode"},
    {type = "string", name = "command"}
}, {
    help = alias_help
})