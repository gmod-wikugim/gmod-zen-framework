module("zen", package.seeall)

---@class zen.panel.zbutton: zen.panel.zpanelbase
local PANEL = {}

function PANEL:Init()
    self.sFont = "Roboto"
    self.sText = "Button"
    self.cTextColor = color_white
    self.cTextColorBG = color_black
    self:SetCursor("hand")
end

function PANEL:SetText(text)
    self.sText = text
end

function PANEL:SetFont(font)
    self.sFont = font
    self:CalcPaintOnce_Internal()
end

---@param w number
---@param h number
function PANEL:PaintOnce(w, h)

    if self:IsHovered() then
        draw.Box(0,0,w,h, "353535")
    else
        draw.Box(0,0,w,h, "212121")
    end
    draw.Text(self.sText, self.sFont, w/2, h/2, self.cTextColor, 1, 1, color_black)
end

vgui.Register("zbutton", PANEL, "zlabel")