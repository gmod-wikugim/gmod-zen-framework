module("zen", package.seeall)

nt.RegisterChannel("map_edit.use")
nt.RegisterChannel("map_edit.status")
nt.RegisterChannel("map_edit.update.pos")
nt.RegisterChannel("map_edit.set.view.entity")

---@class zen.map_edit
map_edit = _GET("map_edit")


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