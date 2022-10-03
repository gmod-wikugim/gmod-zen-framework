local icmd = zen.Import("command")

local I = string.Interpolate

icmd.Register("perm.set", function(QCMD, who, tar_sid64, perm_name, avaliable, target_flags, unique_flags)
    iperm.PlayerSetPermission(tar_sid64, perm_name, avaliable, target_flags, unique_flags)

    local sResult = ""
    if avaliable then
        sResult = I("Successful gived '${s:1}' access to '${s:2}' with flags '${s:3}', ${s:4}", {tar_sid64, perm_name, target_flags, unique_flags})
    else
        sResult = I("Successful restricted '${s:1}' access to '${s:2}' ", {tar_sid64, perm_name})
    end

    return true, sResult
end, {
    {type = "sid64", name = "target"},
    {type = "string_id", name = "perm_name"},
    {type = "bool", name = "avaliable"},
    {type = "uint8", name = "target_flags"},
    {type = "uint8", name = "unique_flags"},
}, {
    perm = "permissions.set",
    help = "Setup permissions for players"
})
