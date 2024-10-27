module("zen", package.seeall)


local PANEL = {}


function PANEL:Init()


end

---@param w number
---@param h number
function PANEL:PaintOnce(w, h)
    draw.BoxRoundedEx(8, 0, 0, w, h, true, true, true, true)
end

function PANEL:GeneratePaintOnce()
    local w, h = self:GetSize()




end



vgui.Register("zpanelbase", PANEL, "EditablePanel")