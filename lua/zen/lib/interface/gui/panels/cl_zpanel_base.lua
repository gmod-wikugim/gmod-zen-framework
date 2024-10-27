module("zen", package.seeall)

---@class zen.panel.zpanelbase: Panel
local PANEL = {}

PANEL.LastPaintW = 0
PANEL.LastPaintH = 0
PANEL.LastPaintHovered = nil

function PANEL:Init()
end

---@param w number
---@param h number
function PANEL:PaintOnce(w, h)
    draw.BoxRoundedEx(8, 0, 0, w, h, true, true, true, true)
end

function PANEL:Paint(w, h)
    if self.LastPaintW != w or self.LastPaintH != h or PANEL.LastPaintHovered != self:IsHovered() then
        self:GeneratePaintOnce()
    end

    if self.PaintOnceMaterial then
        surface.SetDrawColor(255,255,255)
        surface.DrawTexturedRect(0, 0, w, h)
    end
end

---@param w number
---@param h number
function PANEL:PaintMask(w, h)
    surface.SetDrawColor(255,255,255)
    surface.DrawRect(0,0,w,h)
    --draw.BoxRoundedEx(8, 0, 0, w, h, true, true, true, true)
end

function PANEL:GeneratePaintOnce()
    local w, h = self:GetSize()

    self.LastPaintW = w
    self.LastPaintH = h

    self.LastPaintHovered = self:IsHovered()

    self.PaintOnceMaterial = material_cache.Generate2DMaterial(w, h, function(w, h)
        self:PaintOnce(w, h)
    end, function(w, h)
        self:PaintMask(w, h)
    end)
end

vgui.Register("zpanelbase", PANEL, "EditablePanel")