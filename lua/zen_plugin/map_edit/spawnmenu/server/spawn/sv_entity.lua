module("zen", package.seeall)


local function IsValidEntityClass(class)
    local bValid = false

    if !bValid and scripted_ents.Get(class) then
        bValid = true
    end

    if !bValid and list then
        local SpawnableEntities = list.Get( "SpawnableEntities" )
        if SpawnableEntities and SpawnableEntities[class] then
            bValid = true
        end
    end

    return bValid
end

function map_edit.SpawnEntity(class, position, angle)
    local bValidEntityClass = IsValidEntityClass(class)
    if !bValidEntityClass then return false, "This entity does not exist!" end

    local prop = ents.Create(class)
    prop:SetPos(position)
    prop:SetAngles(angle)
    prop:SetSolid(SOLID_VPHYSICS)
    prop:PhysicsInit(SOLID_VPHYSICS)
    prop:Spawn()
    prop:Activate()

    return true
end

nt.RegisterChannel("map_edit.SpawnEntity", nil, {
    types = {"string", "vector", "angle"},
    OnRead = function(self, ply, model, position, angle)
        if not ply:zen_HasPerm("map_edit") then return end
        local success, reason = map_edit.SpawnEntity(model, position, angle)

        if success then
            ply:PrintMessage(HUD_PRINTTALK, "Spawned entity!")
        else
            ply:PrintMessage(HUD_PRINTTALK, "Failed to spawn entity! Reason: ".. reason)
        end
    end,
})
