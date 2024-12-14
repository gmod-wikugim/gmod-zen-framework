module("zen", package.seeall)

---@class zen.activity
activity = _GET("activity")

iperm.RegisterPermission("fun_mode", nil, "Use fun mode stuff")

icmd.Register("fun_mode", function (QCMD, who, cmd, args, tags)
    local bActivate = QCMD:Get("active")

    if bActivate == who:zen_SetVar("fun_mode") then
        return false, (bActivate) and  ("Fun mode already enabled") and ("Fun mode already disabled")
    end

    who:zen_SetVar("fun_mode", bActivate)

    if bActivate then
        who:EmitSound("zen_fun/povar_haha_only.wav")
    else
        who:EmitSound("zen_fun/want_chocolate.wav")
    end


    return true, (bActivate) and ("Fun mode enabled") or ("Fun mode disabled")
end, {
    {name = "active", type = "boolean"}
}, {
    perm = "fun_mode"
})

---@param ply Player
---@param ucmd CUserCMD
ihook.Handler("StartCommand", "zen_fun.StartCommand", function(ply, ucmd)
    if !ply:zen_GetVar("fun_mode") then return end

    local impulse = ucmd:GetImpulse()
    if impulse != 0 then
        ihook.Run("zen_fun.OnImpulse", ply, impulse)
    end
end)
