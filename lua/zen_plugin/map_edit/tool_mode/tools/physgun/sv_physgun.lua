module("zen", package.seeall)

---@class zen_TOOL_physgun_sv: zen_TOOL_physgun
local TOOL = tool.Init("physgun")

function TOOL:OnAttachedEntity(pEntity, pPhysObject)
    print("OnAttachedEntity", pEntity, pPhysObject)

    if IsValid(pPhysObject) then
        local mass = pPhysObject:GetMass()
        pPhysObject:EnableDrag(true)
        pPhysObject:SetDragCoefficient( pPhysObject:GetInvMass() * pPhysObject:GetMass() )
    end
end

function TOOL:OnDetachEntity(pEntity, pPhysObject)
    print("OnDetachedEntity", pEntity, pPhysObject)

    if IsValid(pPhysObject) then
        pPhysObject:EnableDrag(false)
        pPhysObject:SetDragCoefficient(1)
    end
end


function TOOL:Attach(pEntity)
    self.pAttachEntity = pEntity
    self.pPhysObject = pEntity:GetPhysicsObject()

    self:OnAttachedEntity(self.pAttachEntity, self.pPhysObject)
end

function TOOL:Detach(pEntity)
    self:OnDetachEntity(self.pAttachEntity, self.pPhysObject)

    self.pAttachEntity = nil
    self.pPhysObject = nil

end



function TOOL:ServerAction(data)
    local action = data.action
    if !action then return end

    if action == "update_pos"then
        self:UpdateViewPos(data)
    end

    if action == "attach" then
        self:Attach(data.ent)
    end

    if action == "detach" then
        self:Detach(data.ent)
    end
end