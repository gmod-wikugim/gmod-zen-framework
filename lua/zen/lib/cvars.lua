module("zen", package.seeall)

CVARS_VALUES = _L.CVARS_VALUES or {}

CVARS = _L.CVARS or {}

cvars = _GET("cvars", cvars)

local meta = {
    __newindex = function(self, key, value)
        cvars.OnChange(key, value, true)
    end,
    __index = function(self, key)
        return CVARS_VALUES[key]
    end,
    __call = function(self, cvar_name, default, flags, typen, onChange)
        return cvars.Register(cvar_name, default, flags, typen, onChange)
    end,
}
setmetatable(CVARS, meta)

cvars.t_CvarsList = cvars.t_CvarsList or {}
function cvars.OnChange(cvar_name, value, isLuaRun)
    local tConVar = cvars.t_CvarsList[cvar_name]

    if not tConVar then
        cvars.Register(cvar_name, value, 0, typen(value))
        return
    end

    local iType = tConVar.typen

    local old_value = tConVar.value

    local new_value
    if iType then
        new_value = util.StringToTYPE(value, iType)

        if new_value == nil then
            new_value = util.StringToTYPE(old_value, iType)
        end

        if new_value == nil then
            new_value = util.StringToTYPE(tConVar.default, iType)
        end
    end

    tConVar.value = new_value
    CVARS_VALUES[cvar_name] = new_value

    if tConVar.onChange and old_value != new_value then
        tConVar.onChange(cvar_name, old_value, new_value)
    end

    if isLuaRun then
        tConVar.CVAR:SetString(util.TYPEToString(new_value, iType))
    end
end


function cvars.Register(cvar_name, default, flags, typen, onChange)
    CreateConVar(cvar_name, default, flags)

    local CVAR = GetConVar(cvar_name)

    cvars.t_CvarsList[cvar_name] = {
        default = default,
        flags = flags,
        typen = typen,
        onChange = onChange,
        CVAR = CVAR,
    }
    cvars.AddChangeCallback(cvar_name, function(cvar_name, value_old, value_new)
        cvars.OnChange(cvar_name, value_new)
    end, "zen.cvars")

    local value = CVAR:GetString()
    cvars.OnChange(cvar_name, value)
end

function cvars.SetValue(cvar_name, value)
    cvars.OnChange(cvar_name, value)
end


function cvars.GetValue(cvar_name, typen)
    local value = CVARS_VALUES[cvar_name]
    if value != nil then return value end

    local value = GetConVar(cvar_name):GetString()

    return util.StringToTYPE(value, typen)
end

