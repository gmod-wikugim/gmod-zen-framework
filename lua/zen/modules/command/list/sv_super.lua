module("zen", package.seeall)

iperm.RegisterPermission("supermode", "Supermode command")

icmd.Register("supermode", function(QCMD, who)
    who.bZen_SuperMode = true

    return true
end, {}, {
    perm = "supermode",
    help = "Enable super mode"
})

icmd.Register("unsupermode", function(QCMD, who)
    who.bZen_SuperMode = false

    return true
end, {}, {
    perm = "supermode",
    help = "Enable super mode"
})

ihook.Handler("zen.OnClientCommand", "supermode", function(ply, bind_string)
    if !ply.bZen_SuperMode then return end

    -- Force noclip
    if bind_string == "noclip" then
        if ply:GetMoveType() != MOVETYPE_NOCLIP then
            timer.Simple(0.1, function()
                if !IsValid(ply) then return end
                if ply:GetMoveType() != MOVETYPE_NOCLIP then
                    ply:SetMoveType(MOVETYPE_NOCLIP)
                    ply:zen_console_log("Force enabled noclip")
                end
            end)
        end
    end
end)

icmd.Register("set_rank", function(QCMD, who, cmd, args, tags)
    local sid64, usergroup = unpack(args)

    local target = util.GetPlayerEntity(sid64)

    if !IsValid(target) then
        return false, "Player should be online"
    end

    target:SetUserGroup(usergroup)

    return true, "Success setup rank '" .. tostring(usergroup) .. "' to '" .. tostring(target:Nick())
end, {
    {name = "Player", type = "sid64"},
    {name = "UserGroup", type = "string"}
}, {
    perm = "set_rank",
    help = "Set rank to player"
})