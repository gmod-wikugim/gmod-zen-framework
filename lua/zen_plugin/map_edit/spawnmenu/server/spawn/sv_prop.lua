module("zen", package.seeall)

function map_edit.SpawnProp(model, position, angle)
    if IsUselessModel(model) then return false, "This model is useless!" end
    if !util.IsModelLoaded(model) then
        util.PrecacheModel(model)
        if !util.IsModelLoaded(model) then
            return false, "This model not exist!"
        end
    end

    local mesh1, bind1 = util.GetModelMeshes(model)
    if !mesh1 or !bind1 or table.IsEmpty(mesh1) or table.IsEmpty(bind1) then return false, "This model has no meshes!" end

    local prop = ents.Create("prop_physics")
    prop:SetModel(model)
    prop:SetPos(position)
    prop:SetAngles(angle)
    prop:SetSolid(SOLID_VPHYSICS)
    prop:PhysicsInit(SOLID_VPHYSICS)
    prop:Spawn()
    prop:Activate()

    return true
end

nt.RegisterChannel("map_edit.SpawnProp", nil, {
    types = {"string", "vector", "angle"},
    OnRead = function(self, ply, model, position, angle)
        if not ply:zen_HasPerm("map_edit") then return end
        local success, reason = map_edit.SpawnProp(model, position, angle)

        if success then
            msg.ConsoleInterpolate(ply, "Spawned prop: ${s:1}", {model} )
        else
            msg.ErrorInterpolate(ply, "Failed to spawn prop: ${s:1}\n ${s:2}", {reason, model})
        end
    end,
})

