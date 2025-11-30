module("zen")

local PANEL = {} --[[@class zen.icon_model: EditablePanel]]

function PANEL:Init()
    self.lookAt = Vector(0, 0, 0)
    self.camPos = Vector(50, 50, 0)
    self.FOV = 70
    self.model = ""
end

function PANEL:SetCamPos(pos)
    self.camPos = pos

    self:UpdateMaterial()
end

function PANEL:SetLookAt(pos)
    self.lookAt = pos

    self:UpdateMaterial()
end

function PANEL:SetFOV(fov)
    self.FOV = fov

    self:UpdateMaterial()
end

function PANEL:UpdateMaterial()
    icon_generation.GenerateTexture({
        model = self.model,
        lookAt = self.lookAt,
        CamaraPosition = self.camPos,
        FOV = self.FOV,
    }, function (succ, renderTexture, renderMaterial)
        if !succ then
            self.renderMaterial = nil
            return
        end

        self.renderMaterial = renderMaterial
    end)
end

function PANEL:Paint(w, h)
    if self.renderMaterial then
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(self.renderMaterial)
        surface.DrawTexturedRect(0, 0, w, h)
    end
end

function PANEL:SetModel(mdl)
    self.model = mdl

    self:UpdateMaterial()
end

function PANEL:PerformLayout(w, h)
    self:UpdateMaterial()
end

vgui.Register("zen.icon_model", PANEL, "EditablePanel")


-- Concommand to create test panel with icon model
concommand.Add("zen_test_icon_model_panel", function()
    local frame = vgui.Create("DFrame")
    frame:SetSize(500, 600)
    frame:Center()
    frame:SetTitle("Icon Model Panel Test")
    frame:MakePopup()

    local iconModel = vgui.Create("zen.icon_model", frame)
    iconModel:Dock(FILL)
    iconModel:SetModel("models/props_c17/FurnitureCouch002a.mdl")
    iconModel:SetCamPos(Vector(100, 100, 50))
    iconModel:SetLookAt(Vector(0, 0, 0))
    iconModel:SetFOV(70)
end)