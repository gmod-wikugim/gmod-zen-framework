module("zen", package.seeall)

local CLASS = player_mode.GetClass("infected")

---@param ply Player
function CLASS:OnSetup(ply)
    if SERVER then
        ply:SetModel("models/player/zombie_classic.mdl")
    end
end

function CLASS:OnSpawn(ply)
    self:OnSetup(ply)

    -- ply:StripWeapons()
end

function CLASS:OnJoin(ply)
    self:OnSetup(ply)
end


player_mode.Register(CLASS)