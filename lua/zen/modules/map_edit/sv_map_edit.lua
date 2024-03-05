module("zen", package.seeall)

nt.RegisterChannel("map_edit.use")
nt.RegisterChannel("map_edit.status")
nt.RegisterChannel("map_edit.update.pos")
nt.RegisterChannel("map_edit.set.view.entity")

local map_edit = zen.Init("map_edit")

map_edit.t_Players = map_edit.t_Players or {}
local t_Players = map_edit.t_Players
nt.Receive("map_edit.status", {"boolean"}, function(ply, status)
    if not ply:zen_HasPerm("map_edit") then return end

    if status then
        t_Players[ply] = ply:GetPos()
        ply:SetViewEntity(game.GetWorld())
    else
        t_Players[ply] = nil
        ply:SetViewEntity()
    end
end)

nt.Receive("map_edit.update.pos", {"vector"}, function(ply, pos)
    if not ply:zen_HasPerm("map_edit") then return end

    t_Players[ply] = pos
end)

ihook.Listen("PlayerDisconnected", "zen.map_edit", function(ply)
    t_Players[ply] = nil
end)

local AddOriginToPVS = AddOriginToPVS
ihook.Listen("SetupPlayerVisibility", "zen.map_edit", function(ply)
    local pos = t_Players[ply]
    if pos then
        AddOriginToPVS(pos)
    end
end)

nt.Receive("map_edit.use", {"entity"}, function(ply, ent)
    if not ply:zen_HasPerm("map_edit") then return end

    ent:Fire("Use")
end)

nt.Receive("map_edit.set.view.entity", {"entity"}, function(ply, ent)
    if not ply:zen_HasPerm("map_edit") then return end

    ply:SpectateEntity(ent)
end)

function map_edit.SpawnProp(model, position, angle)
    if IsUselessModel(model) then return false, "This model is useless!" end
    if !util.IsModelLoaded(model) then util.PrecacheModel(model) end

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
            ply:PrintMessage(HUD_PRINTTALK, "Spawned prop!")
        else
            ply:PrintMessage(HUD_PRINTTALK, "Failed to spawn prop! Reason: ".. reason)
        end
    end,
})


nt.RegisterChannel("map_edit.tool_mode.ServerAction", nil, {
    types = {"string", "table"},
    OnRead = function(self, ply, tool_id, data)
        if not ply:zen_HasPerm("map_edit") then return end

        local TOOL = map_edit.tool_mode.Get(tool_id)
        if !TOOL then return end

        if TOOL.ServerAction then
            TOOL.ServerAction(ply, data)
        end
    end,
})
