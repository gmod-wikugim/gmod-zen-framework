module("zen", package.seeall)



local PANEL = {}


function PANEL:Init()
    self.Entity = NULL
    self.iIcon_Width = 512
    self.iIcon_Height = 512
end


---@param mdl string
function PANEL:SetModel(mdl)
    if IsValid(self.Entity) then
        self.Entity:Remove()
    end
    self.Entity = nil

    self.Entity = ClientsideModel(mdl, RENDERGROUP_OPAQUE)
    self.Entity:SetNoDraw(true)
end

function PANEL:GetEntity()
    return self.Entity
end


function PANEL:OnRemove()
    if IsValid(self.Entity) then
        self.Entity:Remove()
    end
    self.Entity = nil
end


gui.RegisterStylePanel("spawn_icon", PANEL, "EditablePanel")