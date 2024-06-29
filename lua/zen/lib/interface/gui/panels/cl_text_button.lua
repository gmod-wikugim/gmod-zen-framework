module("zen", package.seeall)

surface.CreateFont("zen.gui.text_button.Main", {
    font = "Segoe UI",
    size = 18,
    weight = 300,
})

local PANEL = {}


function PANEL:Init()
    self.pnlLabel = self:Add("DLabel")
    self.pnlLabel:SetFont("zen.gui.text_button.Main")
    self.pnlLabel:SetText("button")
    self.pnlLabel:SetMouseInputEnabled(false)
    self.pnlLabel:SetContentAlignment(5)

    self:SetCursor("hand")
    self:SetMouseInputEnabled(true)
    self:StretchToParent(-5,0,-5,0)
end

function PANEL:DoClick() end
function PANEL:DoRightClick() end

function PANEL:OnMousePressed(mouse)
    if mouse == MOUSE_LEFT then
        self:DoClick()
    end
    if mouse == MOUSE_RIGHT then
        self:DoRightClick()
    end
end

function PANEL:Paint(w, h)
    if self:IsHovered() then
        draw.Box(0,0,w,h,COLOR.HOVER)
    end
end

function PANEL:SetFont(font)
    self.pnlLabel:SetFont(font)
end

function PANEL:SetText(text)
    self.pnlLabel:SetText(text)

    local cw, ch = self.pnlLabel:GetContentSize()
    self.pnlLabel:SetSize(cw + 10, cw)
    self:SizeToChildren(true, true)
end

function PANEL:PerformLayout(w, h)
    if IsValid(self.pnlLabel) then
        self.pnlLabel:Center()
    end
end


gui.RegisterStylePanel("text_button", PANEL, "EditablePanel")