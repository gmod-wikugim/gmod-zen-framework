module("zen", package.seeall)

local PANEL = {}

local _SizeToChildren = META.PANEL.SizeToChildren

function PANEL:Init()
    self.bChangeWide = false
    self.bChangeTall = true
end

---@param updateWide boolean
---@param updateTall boolean
function PANEL:AutoSize(updateWide, updateTall)
    self.bChangeWide = updateWide
    self.bChangeTall = updateTall
end

function PANEL:InstallOnChangeSizeHook(pnlChild)
    pnlChild.OnSizeChanged = function()
        _SizeToChildren(self, self.bChangeWide, self.bChangeTall)
    end
end

function PANEL:RemoveOnChangeSizeHook(pnlChild)
    pnlChild.OnSizeChanged = nil
end

function PANEL:OnChildAdded( child )
    self:InstallOnChangeSizeHook(child)

    if self.PostChildAdded then
        self.PostChildAdded(child)
    end
end

function PANEL:OnChildRemoved( child )
    self:RemoveOnChangeSizeHook(child)

    if self.PostChildRemoved then
        self.PostChildRemoved(child)
    end
end

gui.RegisterStylePanel("content", PANEL, "EditablePanel")