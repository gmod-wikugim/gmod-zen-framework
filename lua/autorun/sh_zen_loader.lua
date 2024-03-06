module("zen", package.seeall)
_L = getfenv()

AddCSLuaFile("zen/main/main.lua")
include("zen/main/main.lua")

concommand.Add("zen_reload", function(ply)
    if SERVER and IsValid(ply) then return end
    include("zen/main/main.lua")
end)

concommand.Add("zen_reload_full", function(ply)
    if SERVER and IsValid(ply) then return end

    nt = nil
    zen = nil
    include("zen/main/main.lua")
end)