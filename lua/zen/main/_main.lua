
module("zen", function(MODULE)
    --- Init global vartiable
    MODULE._L = MODULE
    MODULE.zen = MODULE
    MODULE.MODULE = MODULE
    MODULE.Autorun = Autorun

    --- Setup main metatable
    setmetatable(MODULE, {
        __index = _G
    })
end)

zen.bAutoRunEnabled = type(Autorun) == "table" and type(Autorun.require) == "function"

zen.SEND_CLIENT_FILES = true
zen.SERVER_SIDE_ACTIVATED = false

if zen.bAutoRunEnabled then
    zen.SERVER_SIDE_ACTIVATED = false
end


---@param path string
function zen.INC(path)
    assert(type(path) == "string", "path not is string")

    if zen.bAutoRunEnabled then
        return Autorun.require(path)
    else
        local res, a1, a2, a3, a4, a5, a6, a7 = xpcall(include, ErrorNoHaltWithStack, path)
        if res then
            return a1, a2, a3, a4, a5, a6, a7
        end
    end
end


if SERVER then
    if zen.SERVER_SIDE_ACTIVATED then
        util.AddNetworkString("zen.ping")
    end
end

if CLIENT_DLL then
    local NetworkID = util.NetworkStringToID("zen.ping")

    if !NetworkID or NetworkID <= 0 then
        print("ZEN: Looks like server don't have ZEN. Enabled client-only mode")
        zen.SERVER_SIDE_ACTIVATED = false
    else
        zen.SERVER_SIDE_ACTIVATED = true
    end
end


--- Include server, filter is activate
function zen.IncludeSV(path)
    if (zen.SERVER_SIDE_ACTIVATED) != true then return end

    if SERVER then return zen.INC(path) end
end

--- Include server, filter ignored
function zen.IncludeSVU(path)
    if SERVER then return zen.INC(path) end
end

--- Include client, filter ignored
function zen.IncludeCL(path)
    if SERVER then AddCSLuaFile(path) end
    if CLIENT_DLL then return zen.INC(path) end
end

--- Include client and server, filter is activate
function zen.IncludeSH(path)
    if SERVER then AddCSLuaFile(path) end
    if SERVER and (zen.SERVER_SIDE_ACTIVATED) != true then return end
    if CLIENT_DLL or SERVER then zen.INC(path) end
end

--- Include client and server, filter ignored
function zen.IncludeSHU(path)
    if SERVER then AddCSLuaFile(path) end
    if CLIENT_DLL or SERVER then zen.INC(path) end
end



zen.IncludeSHU("zen/main/main.lua")

concommand.Add("zen_reload", function(ply)
    if SERVER and IsValid(ply) then return end

    zen.IncludeSHU("zen/main/main.lua")
end)

concommand.Add("zen_reload_full", function(ply)
    if SERVER and IsValid(ply) then return end

    zen = nil
    zen.IncludeSHU("zen/main/main.lua")
end)