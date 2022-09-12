local gmod = gmod
local pairs = pairs
local isfunction = isfunction
local isstring = isstring
local isnumber = isnumber
local isbool = isbool
local IsValid = IsValid
local type = type
local ErrorNoHaltWithStack = ErrorNoHaltWithStack

HOOK_LEVEL_PREVENT = -9999
HOOK_LEVEL_BROWSER = -998

HOOK_LEVEL_FIRST = -1000

HOOK_LEVEL_DEFAULT_PRE = -1
HOOK_LEVEL_DEFAULT = 0
HOOK_LEVEL_DEFAULT_POST = 1

HOOK_LEVEL_LAST = 1000

ZEN_HOOKS = true

hook = hook or {}

local clr_red = Color(255,0,0)
local clr_white = Color(255,255,255)

hook.t_HooksGetTable = hook.t_HooksGetTable or {}
hook.t_Hooks = hook.t_Hooks or {}
hook.t_Hooks_Cleared = hook.t_Hooks_Cleared or {}
local Hooks_GetTable = hook.t_HooksGetTable
local Hooks = hook.t_Hooks
local Hook_Cleared = hook.t_Hooks_Cleared


function hook.Sort_Internal(event_name)
    local tHooksList = Hooks[event_name]
    Hook_Cleared[event_name] = {}
    local tHookClears = Hook_Cleared[event_name]

    for hook_id, v in pairs(tHooksList) do
        table.insert(tHookClears, v)
    end

    table.sort(tHookClears, function (a, b) return a.level < b.level end)
end

function hook.Error(err, name, identify)
    MsgC(clr_red, "[Hook-Error] ", clr_white, name, ":", identify, "\n")
    ErrorNoHaltWithStack(err)
end
local hook_Error = hook.Error

local i = 0
local sucRun, a1, a2, a3, a4, a5, a6, a7, a8, a9
function hook.Call_Internal(event_name, gm, ...)
    local tHookClears = Hook_Cleared[event_name]

    if tHookClears != nil then
        i = 0
        ::go_next::
        i = i + 1

        local tHook = tHookClears[i]
        if tHook != nil then
            if tHook.IsValidCheck == true then
                local id = tHook.id
                if IsValid(id) then
                    sucRun, a1, a2, a3, a4, a5, a6, a7, a8, a9 = pcall(tHook.func, id, ...)
                    goto check_result
                else
                    hook.Remove(event_name, id)
                    goto go_next
                end
            else
                sucRun, a1, a2, a3, a4, a5, a6, a7, a8, a9 = pcall(tHook.func, ...)
            end

            ::check_result::

            if sucRun == false then hook_Error(a1, event_name, tHook.id) goto go_next end

            if tHook.IsListener != true and a1 != nil then
                return a1, a2, a3, a4, a5, a6, a7, a8, a9
            end

            goto go_next
        end
    end


    if gm == nil then return end
    local gm_func = gm[event_name]
    if gm_func != nil then return gm_func(gm, ...) end
end
local hook_Call = hook.Call_Internal

function hook.Add_Internal(event_name, hook_id, func, level, IsListener)
    if ( !isstring( event_name ) ) then ErrorNoHaltWithStack( "bad argument #1 to 'Add' (string expected, got " .. type( event_name ) .. ")" ) return end
	if ( !isfunction( func ) ) then ErrorNoHaltWithStack( "bad argument #3 to 'Add' (function expected, got " .. type( func ) .. ")" ) return end

	local notValid = hook_id == nil || isnumber( hook_id ) or isbool( hook_id ) or isfunction( hook_id ) or !hook_id.IsValid or !IsValid( hook_id )
	if ( !isstring( hook_id ) and notValid ) then ErrorNoHaltWithStack( "bad argument #2 to 'Add' (string expected, got " .. type( hook_id ) .. ")" ) return end

    Hooks[event_name] = Hooks[event_name] or {}
    Hooks_GetTable[event_name] = Hooks_GetTable[event_name] or {}

    local IsValidCheck = isstring(hook_id) and true or false

    Hooks[event_name][hook_id] = {
        id = hook_id,
        func = func,
        level = level or HOOK_LEVEL_DEFAULT,
        IsValidCheck = IsValidCheck,
        ValidFunc = hook_id.IsValid,
        IsListener = IsListener,
    }
    Hooks_GetTable[event_name][hook_id] = func

    hook.Sort_Internal(event_name)
end

function hook.GetTable() return Hooks_GetTable end

function hook.Remove_Internal(event_name, hook_id)
    if ( !isstring( event_name ) ) then ErrorNoHaltWithStack( "bad argument #1 to 'Remove' (string expected, got " .. type( event_name ) .. ")" ) return end

	local notValid = isnumber( hook_id ) or isbool( hook_id ) or isfunction( hook_id ) or !hook_id.IsValid or !IsValid( hook_id )
	if ( !isstring( hook_id ) and notValid ) then ErrorNoHaltWithStack( "bad argument #2 to 'Remove' (string expected, got " .. type( hook_id ) .. ")" ) return end

	if ( !Hooks[ event_name ] ) then return end

    if Hooks[event_name] or Hooks_GetTable[event_name] then
        Hooks[event_name][hook_id] = nil
        Hooks_GetTable[event_name][hook_id] = nil

        hook.Sort_Internal(event_name)
    end
end


function hook.Add( event_name, identify, func, level ) hook.Add_Internal(event_name, identify, func, level) end
function hook.Remove( event_name, identify ) hook.Remove_Internal(event_name, identify) end

hook.Call = hook_Call
function hook.Run( name, ... ) return hook_Call( name, gmod and gmod.GetGamemode() or nil, ... ) end

-- New Stuff
function hook.Listen(name, identify, func, level) hook.Add_Internal(name, identify, func, level, true) end
function hook.Handler(name, identify, func, level) hook.Add_Internal(name, identify, func, level) end