module("zen")

---@class zen.panel.zlabel: zen.panel.zpanelbase
local PANEL = {}

function PANEL:Init()
    self.sText = "ExampleText"
    self.cTextColor = color_white
    self.cTextColorBG = color_black
    self:SetCursor("hand")
    self:SetFont("14:DejaVu Sans")
end

function PANEL:GetText() return self.sText end
function PANEL:SetText(text)
    self.sText = text

    self:CalcPaintOnce_Internal()
end

function PANEL:SetFont(font)
    self.sFont = ui.ffont(font)
    self:CalcPaintOnce_Internal()
end

---@param add_x number?
function PANEL:SizeToContentsX(add_x)
    add_x = add_x or 0
    surface.SetFont(self.sFont)
    local w, h = surface.GetTextSize(self.sText)

    self:SetWide(w + add_x)
end

---@param add_y number?
function PANEL:SizeToContentsY(add_y)
    add_y = add_y or 0
    surface.SetFont(self.sFont)
    local w, h = surface.GetTextSize(self.sText)

    self:SetTall(h + add_y)
end

---@param add_x number?
---@param add_y number?
function PANEL:SizeToContents(add_x, add_y)
    add_x = add_x or 0
    add_y = add_y or 0
    surface.SetFont(self.sFont)
    local w, h = surface.GetTextSize(self.sText)

    self:SetSize(w + add_x, h + add_y)
end

---@param w number
---@param h number
function PANEL:PaintOnce(w, h)
    draw.Text(self.sText, self.sFont, w/2, h/2, self.cTextColor, 1, 1, color_black)
end

vgui.Register("zlabel", PANEL, "zpanelbase")