module("zen", package.seeall)

---@class zen_TOOL_physgun_cl: zen_TOOL_physgun
local TOOL = tool.Init("physgun")

function TOOL:EnableGrab()
    if gui.IsGameUIVisible() then return end
    if IsValid(vgui.GetKeyboardFocus()) then return end

    self.bGrabEnabled = true
end

function TOOL:DisableGrab()
    self:DetachEntity()

    self.bGrabEnabled = false
end

function TOOL:DetachEntity()
    if self.pAttachEntity then
        self:OnDetachEntity(self.pAttachEntity, self.pPhysObject)
    end

    self.pAttachEntity = nil
    self.pPhysObject = nil
end

---@param pEntity Entity
function TOOL:AttachEntity(pEntity)
    if self.pAttachEntity then return end
    if !IsValid(pEntity) then return end

    self.pAttachEntity = pEntity
    self.pPhysObject = pEntity:GetPhysicsObject()

    self:OnAttachedEntity(pEntity, self.pPhysObject)
end


function TOOL:OnAttachedEntity(pEntity, pPhysObject)
    print("OnAttachedEntity", pEntity, pPhysObject)

    self:CallServerAction{
        action = "attach",
        ent = pEntity,
    }
end

function TOOL:OnDetachEntity(pEntity, pPhysObject)
    print("OnDetachedEntity", pEntity, pPhysObject)

    self:CallServerAction{
        action = "detach",
        ent = pEntity,
    }
end

function TOOL:Think()
    if self.bGrabEnabled then
        local pHoverEntity = map_edit.GetHoverEntity()
        if IsValid(pHoverEntity) then
            self:AttachEntity(pHoverEntity)
        end
    end
end

function TOOL:Render(rendermode, priority, vw)
    if self.pAttachEntity then
        if rendermode == RENDER_2D then
            draw3d.Line(vw.origin + Vector(0, 0, -1), self.pAttachEntity:GetPos(), Color(0,125, 255))
        end
    end
end

function TOOL:OnDie()
    self:DisableGrab()
end


function TOOL:OnButtonPress(but, in_key, bind_name)
    if bind_name == "+attack" then
        self:EnableGrab()
    end
end

function TOOL:OnButtonUnPress(but, in_key, bind_name)
    if bind_name == "+attack" then
        self:DisableGrab()
    end
end