icmd.registerCommand("perm.set", {"sid64", "string", "string", "string", "string"}, function(ply, tar_sid64, perm_name, avaliable, target_flags, unique_flags)
    tar_sid64, perm_name, avaliable, target_flags, unique_flags = tar_sid64, perm_name, tobool(avaliable), tonumber(target_flags), tonumber(unique_flags)
    iperm.PlayerSetPermission(tar_sid64, perm_name, avaliable, target_flags, unique_flags)

    local sResult = ""
    if avaliable then
        sResult = string.Interpolate("Successful gived '${s:1}' access to '${s:2}' with flags '${s:3}', ${s:4}", {tar_sid64, perm_name, target_flags, unique_flags})
    else
        sResult = string.Interpolate("Successful restricted '${s:1}' access to '${s:2}' ", {tar_sid64, perm_name})
    end

    return true, sResult
end)

iperm.RegisterPermission("public", iperm.flags.NO_TARGET, "Permissions for public/always allowed commands")

icmd.registerCommand("auth", {}, function(ply)
    if ply:zen_GetVar("auth") then
        return false, "You already authed"
    end

    ply:zen_SetVar("auth", true)

    return true, "Sucess Auth"
end, "public")

icmd.registerCommand("unauth", {}, function(ply)
    if not ply:zen_GetVar("auth") then
        return false, "You already authed"
    end

    ply:zen_SetVar("auth", false)

    return true, "Sucess UnAuth"
end, "public")