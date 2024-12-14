module("zen", package.seeall)

local CLASS = player_mode.GetClass("infected")

CLASS:HookServer("PlayerSetModel", function(self, ply)
    if !self:IsTeamMate(ply) then return end

    ply:SetModel("models/player/zombie_classic.mdl")
    return true
end)

CLASS:HookServer("PlayerLoadout", function(self, ply)
    if !self:IsTeamMate(ply) then return end

    ply:StripWeapons()

    return true
end)

CLASS:HookServer("PlayerCanPickupWeapon", function(self, ply, wep)
    if !self:IsTeamMate(ply) then return end

    return false
end)


CLASS:HookServer("PlayerCanPickupItem", function (self, ply)
    if !self:IsTeamMate(ply) then return end

    return false
end)

CLASS:HookServer("AllowPlayerPickup", function(self, ply)
    if !self:IsTeamMate(ply) then return end

    return false
end)


player_mode.Register(CLASS)

icmd.Register("be_infected", function (QCMD, who, cmd, args, tags)
    player_mode.SetMode(who, "infected")

    return true, "You are infected now"
end)