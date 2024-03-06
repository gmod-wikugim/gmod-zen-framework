module("zen", package.seeall)


do
    local i, lastcolor
    local MsgC = MsgC
    local color_warn = Color(255, 0, 0)
    local IsColor = IsColor
    function warn(...)
        if !_CFG.bZen_Developer then return end
        local args = {...}
        local count = #args

        i = 0

        MsgC(_COLOR.main, "z", COLOR.WARN, " WARN> ", color_warn)
        if count > 0 then
            while i < count do
                i = i + 1
                local dat = args[i]
                if IsColor(dat) then
                    lastcolor = dat
                    continue
                end
                if lastcolor then
                    MsgC(lastcolor, dat)
                    lastcolor = nil
                else
                    MsgC(dat)
                end
            end
        end
        MsgC("\n", COLOR.WHITE)
    end
end

do
    local i, lastcolor
    local MsgC = MsgC
    local IsColor = IsColor
    function log_error(...)
        local args = {...}
        local count = #args

        i = 0

        MsgC(_COLOR.main, "z", COLOR.ERROR, " ERROR> ")
        if count > 0 then
            while i < count do
                i = i + 1
                local dat = args[i]
                if IsColor(dat) then
                    lastcolor = dat
                    continue
                end
                if lastcolor then
                    MsgC(lastcolor, dat)
                    lastcolor = nil
                else
                    MsgC(dat)
                end
            end
        end
        MsgC("\n", COLOR.WHITE)
    end
end

if CLIENT then
    cvars.Register("zen_developer", 0, FCVAR_ARCHIVE + FCVAR_UNLOGGED + FCVAR_SERVER_CAN_EXECUTE + FCVAR_NEVER_AS_STRING + FCVAR_DONTRECORD + FCVAR_CLIENTCMD_CAN_EXECUTE,
    TYPE.NUMBER,
    function(cvar_name, old_value, new_value)
        if (isnumber(new_value) and new_value > 0) then
            _CFG.bZen_Developer = true
            warn("Developer mode is ", COLOR.GREEN, "enabled")
        else
            _CFG.bZen_Developer = false
            warn("Developer mode is ", COLOR.RED ,"disabled")
        end
    end)
end