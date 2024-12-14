module("zen", package.seeall)

---@class zen_TOOL
local TOOL = {}
TOOL.id = "move"
TOOL.Name = "Move"
TOOL.Description = "Move"

function TOOL:Init()

end

function TOOL:UpdateViewPos(data)
    local pos = data.pos
    local ang = data.ang
    local ent = self.eGrabbedEntity

    if IsValid(ent) then
        ent:SetPos(pos)
        ent:SetAngles(ang)
    end

end

function TOOL:Grab(data)
    local ent = data.ent

    if !IsValid(ent) then return end

    self.eGrabbedEntity = ent

    ent:SetMoveType(MOVETYPE_CUSTOM)
    ent:SetSolid(SOLID_NONE)
end

function TOOL:Ungrab(data)
    local ent = self.eGrabbedEntity

    self.eGrabbedEntity = nil

    if IsValid(ent) then
        ent:PhysicsInit(data.solid)
        ent:SetMoveType(data.movetype)
    end
end


function TOOL:ServerAction(data)
    local action = data.action
    if !action then return end

    if action == "update_pos"then
        self:UpdateViewPos(data)
    end

    if action == "grab" then
        self:Grab(data)
    end

    if action == "ungrab" then
        self:Ungrab(data)
    end

end

tool.Register(TOOL)