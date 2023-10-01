if CLIENT then
    cvars.Register("zen_developer", 0, FCVAR_ARCHIVE + FCVAR_UNLOGGED + FCVAR_SERVER_CAN_EXECUTE + FCVAR_NEVER_AS_STRING + FCVAR_DONTRECORD + FCVAR_CLIENTCMD_CAN_EXECUTE, 
    TYPE.NUMBER,
    function(cvar_name, old_value, new_value)
        if (isnumber(new_value) and new_value > 0) then
            icfg.bZen_Developer = true
            MsgC(COLOR.WARN, "[NT-Predicted-Warn] Developer mode is ", COLOR.GREEN, "enabled \n")
        else
            icfg.bZen_Developer = false
            MsgC(COLOR.WARN, "[NT-Predicted-Warn] Developer mode is ", COLOR.RED ,"disabled \n")
        end
    end)
end