module("zen", package.seeall)

---@class zen.panel.ztree: zen.panel.ztree_node
local PANEL = {}

function PANEL:Init()
    self.bMainTree = true
    self:DockMargin(0,0,0,0)

    if IsValid(self.pnlButton) then
        self.pnlButton:Remove()
    end
end

vgui.Register("ztree", PANEL, "ztree_node")
