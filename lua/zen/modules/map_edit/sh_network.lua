module("zen", package.seeall)

nt.RegisterChannel("map_edit.SpawnProp", nil, {
    types = {"string", "vector", "angle"},
    OnRead = function(self, ply, model, position, angle)
        if not ply:zen_HasPerm("map_edit") then return end

        if SERVER then
            local prop = ents.Create("prop_physics")
            prop:SetModel(model)
            prop:SetPos(position)
            prop:SetAngles(angle)
            prop:SetSolid(SOLID_VPHYSICS)
            prop:PhysicsInit(SOLID_VPHYSICS)
            prop:Spawn()
            prop:Activate()
        end
    end,
})
