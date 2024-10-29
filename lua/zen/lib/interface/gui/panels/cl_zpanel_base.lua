module("zen", package.seeall)

---@class zen.panel.zpanelbase: Panel
---@field OnMouseLeftPress? fun(self) Called when pressed MOUSE_LEFT
---@field OnMouseRightPress? fun(self) Called when pressed MOUSE_RIGHT
---@field OnMouseMiddlePress? fun(self) Called when pressed MOUSE_MIDDLE
---@field OnMouse4Press? fun(self) Called when pressed MOUSE_4
---@field OnMouse5Press? fun(self) Called when pressed MOUSE_5
---@field DoClick? fun(self) Called when release MOUSE_LEFT
---@field DoRightClick? fun(self) Called when release MOUSE_RIGHT
---@field OnMouseLeftRelease? fun(self, delta:number) Called when Release MOUSE_LEFT, delta - time left from presse
---@field OnMouseRightRelease? fun(self, delta:number) Called when Release MOUSE_RIGHT, delta - time left from presse
---@field OnMouseMiddleRelease? fun(self, delta:number) Called when Release MOUSE_MIDDLE, delta - time left from presse
---@field OnMouse4Release? fun(self, delta:number) Called when Release MOUSE_4, delta - time left from presse
---@field OnMouse5Release? fun(self, delta:number) Called when Release MOUSE_5, delta - time left from presse
---@field Draw? fun(self, w:number, h:number) Alias to default Paint
---@field DrawOver? fun(self, w:number, h:number) Alias to default PaintOver
---@field OnSizeChanged? fun(self, w:number, h:number)
---@field OnCursorJoin fun(self) Called when cursor joined to Panel
---@field OnCursorExit fun(self) Called when cursor exited after exit Panel
---@field PaintMask fun(self, w:number, h:number) -- Mask for PaintOnce
---@field PaintOnce fun(self, w:number, h:number) -- Paint which called when panel: ChangeSize. (Un)Hovered. (De)Enable. (De)Blocked
local PANEL = {}

PANEL.bPaintOnceEnabled = true
PANEL.LastPaintW = -1
PANEL.LastPaintH = -1

PANEL.LastPerformW = -1
PANEL.LastPerformH = -1

---@private
PANEL.bHoverPaintOnceEnabled = false

---@private
PANEL.bAutoResizeToChildrenWidth = false

---@private
PANEL.bAutoResizeToChildrenHeight = false

---@private
PANEL.bNeedUpdateSizeToChildren = false

PANEL.bEnabled = true
PANEL.bDisabled = !PANEL.bEnabled

--- Show Panel is blocked. Is blocked, then input press/release also is blocked
PANEL.bBlocked = false

PANEL.tMousesPressed = {}
PANEL.tMousesPressTime = {}

--- Check is mouse pressed to panel, nil arg check any mouse is pressed
---@param mouse integer?
---@return boolean
function PANEL:IsMousePressed(mouse)
    if (mouse == nil) then return next(self.tMousesPressed) != nil end

    return self.tMousesPressed[mouse] != nil
end

function PANEL:IsMouseLeftPressed() return self:IsMousePressed(MOUSE_LEFT) end
function PANEL:IsMouseRightPressed() return self:IsMousePressed(MOUSE_RIGHT) end
function PANEL:IsMouseMiddlePressed() return self:IsMousePressed(MOUSE_MIDDLE) end
function PANEL:IsMouse4Pressed() return self:IsMousePressed(MOUSE_4) end
function PANEL:IsMouse5Pressed() return self:IsMousePressed(MOUSE_5) end


function PANEL:Init()
    self:SetMouseInputEnabled(true)
end

function PANEL:IsEnabled() return self.bEnabled end
function PANEL:IsDisabled() return self.bDisabled end

--- Enable Panel, bState default is [true]
---@param bState? boolean
function PANEL:SetEnabled(bState)
    if bState == nil then bState = true end

    local bStateChanged = self.bEnabled != bState

    self.bEnabled = bState
    self.bDisabled = !bState

    if bStateChanged then
        self:CalcPaintOnce_Internal()
    end
end

function PANEL:Enable() self:SetEnabled(true) end
function PANEL:Disable() self:SetEnabled(false) end

function PANEL:IsBlocked() return self.bBlocked end

--- Block Panel, bState default is [true]. Block MousePress/Release. Kill Focus for Keyboard.
---@param bState? boolean
function PANEL:SetBlocked(bState)
    if bState == nil then bState = true end

    local bStateChanged = self.bBlocked != bState

    self.bBlocked = bState

    if bState == true then
        if vgui.GetKeyboardFocus() then self:KillFocus() end

        table.Empty(self.tMousesPressTime)
        table.Empty(self.tMousesPressed)
    end

    if bStateChanged then
        self:CalcPaintOnce_Internal()
    end
end

--- Block MousePress/Release. Kill Focus for Keyboard.
function PANEL:Block() self:SetBlocked(true) end
function PANEL:UnBlock() self:SetBlocked(false) end

local t_isWideDock = {
    LEFT = true,
    RIGHT = true,
    TOP = true,
    BOTTOM = true
}

--- Smart dock with Invalidate Parent
---@param dock integer
---@param size number?
function PANEL:SDock(dock, size)
    if type(size) == "number" then
        if t_isWideDock[dock] then
            self:SetWide(size)
        else
            self:SetTall(size)
        end
    end

    self:Dock(dock)
    self:InvalidateParent(true)
end

function PANEL:SFill()
    self:Dock(FILL)
    self:InvalidateParent(true)
end

/*
---@param w number
---@param h number
function PANEL:PaintOnce(w, h)
    -- draw.BoxRoundedEx(8, 0, 0, w, h, color_white, true, true, true, true)
end
*/

/* PaintMask Example
---@param w number
---@param h number
function PANEL:PaintMask(w, h)
    surface.SetDrawColor(255,255,255)
    surface.DrawRect(0,0,w,h)
end
*/

--- Return currect cursor position, return -1, -1 when cursor no visible
---@return number, number
function PANEL:GetLocalCursorPos()
    if vgui.CursorVisible() != true then return -1, -1 end

    local cx, cy = input.GetCursorPos()
    local x, y = vgui.GetWorldPanel():GetChildPosition(self)

    return cx - x, cy - y
end

--- Return is cursor in panel
---@return boolean
function PANEL:IsCursorInside()
    if vgui.CursorVisible() != true then return false end

    local cx, cy = self:GetLocalCursorPos()

    local w, h = self:GetSize()

    return cx > 0 and cy > 0 and cx < w and cy < h
end

---@private
function PANEL:Paint(w, h)
    if self.bPaintOnceEnabled then
        /* Looks Like Useless! TODO: Remove later
        local bStateHovered = self:IsHovered()
        if self.LastPaintHovered != bStateHovered then
            self:CalcPaintOnce(nil, nil, bStateHovered)
        end
        */


        if self.PaintOnceMaterial then
            surface.SetMaterial(self.PaintOnceMaterial)
            surface.SetDrawColor(255,255,255)
            surface.DrawTexturedRect(0, 0, w, h)
        end
    end

    if self.Draw then
        self:Draw(w, h)
    end

    if self.DrawOver then
        self:DrawOver(w, h)
    end
end

---@param mouse integer
function PANEL:OnMousePressed(mouse)
    if self:IsBlocked() then return end

    self.tMousesPressed[mouse] = true
    self.tMousesPressTime[mouse] = CurTime()

    if mouse == MOUSE_LEFT and type(self.OnMouseLeftPress) == "function" then self:OnMouseLeftPress() end
    if mouse == MOUSE_RIGHT and type(self.OnMouseRightPress) == "function" then self:OnMouseRightPress() end
    if mouse == MOUSE_MIDDLE and type(self.OnMouseMiddlePress) == "function" then self:OnMouseMiddlePress() end
    if mouse == MOUSE_4 and type(self.OnMouse4Press) == "function" then self:OnMouse4Press() end
    if mouse == MOUSE_5 and type(self.OnMouse5Press) == "function" then self:OnMouse5Press() end
end

function PANEL:SizeToScreen()
    local w, h = ScrW(), ScrH()

    self:SetSize(w, h)
end

---@param mouse integer
function PANEL:OnMouseReleased(mouse)
    if self:IsBlocked() then return end

    // Ignore no pressed early buttons
    if (self.tMousesPressed[mouse] == nil) then return end

    local delta = CurTime() - self.tMousesPressTime[mouse]

    self.tMousesPressed[mouse] = nil

    if mouse == MOUSE_LEFT and type(self.DoClick) == "function" then self:DoClick() end
    if mouse == MOUSE_RIGHT and type(self.DoRightClick) == "function" then self:DoRightClick() end

    if mouse == MOUSE_LEFT and type(self.OnMouseLeftRelease) == "function" then self:OnMouseLeftRelease(delta) end
    if mouse == MOUSE_RIGHT and type(self.OnMouseRightRelease) == "function" then self:OnMouseRightRelease(delta) end
    if mouse == MOUSE_MIDDLE and type(self.OnMouseMiddleRelease) == "function" then self:OnMouseMiddleRelease(delta) end
    if mouse == MOUSE_4 and type(self.OnMouse4Release) == "function" then self:OnMouse4Release(delta) end
    if mouse == MOUSE_5 and type(self.OnMouse5Release) == "function" then self:OnMouse5Release(delta) end
end

---@private
---@param width number?
---@param height number?
function PANEL:CalcPaintOnce_Internal(width,  height)
    if type(self.PaintOnce) != "function" then return end

    if (width == nil) then width = self:GetWide() end
    if (height == nil) then height = self:GetTall() end

    if self.PaintMask then
        self.PaintOnceMaterial, PNG = material_cache.Generate2DMaterial(width, height, function(w, h)
            self:PaintOnce(w, h)
        end, function(w, h)
            self:PaintMask(w, h)
        end)
    else
        self.PaintOnceMaterial, PNG = material_cache.Generate2DMaterial(width, height, function(w, h)
            self:PaintOnce(w, h)
        end)
    end
end

/*
---@private
---@param width number?
---@param height number?
---@param bHovered boolean?
function PANEL:CalcPaintOnce(width, height, bHovered)
    -- Check is nil. It's work with predict in PerformLayout and OnCursor event
    if (width == nil) then width = self:GetWide() end
    if (height == nil) then height = self:GetTall() end
    -- if (bHovered == nil) then bHovered = self:IsHovered() end

    local bNeedChange = false

    if !bNeedChange and self.LastPaintW != width then bNeedChange = true end
    if !bNeedChange and self.LastPaintH != height then bNeedChange = true end
    -- if !bNeedChange and self.LastPaintHovered != bHovered then bNeedChange = true end

    if bNeedChange != true then return end

    self.LastPaintW = width
    self.LastPaintH = height
    self.LastPaintHovered = bHovered

    self:CalcPaintOnce_Internal(width, height)
end
*/

--- Enable Auto resize panel width to children in PerformLayout
---@param bState boolean
function PANEL:SetAutoReSizeToChildrenWidth(bState)
    self.bAutoResizeToChildrenWidth = bState

    self:InvalidateLayout()
end

--- Enable Auto resize panel height to children in PerformLayout
---@param bState boolean
function PANEL:SetAutoReSizeToChildrenHeight(bState)
    self.bAutoResizeToChildrenHeight = bState

    self:InvalidateLayout()
end

--- Enable Auto resize panel width and height to children size
---@param bState boolean
function PANEL:SetAutoReSizeToChildren(bState)
    self.bAutoResizeToChildrenWidth = bState
    self.bAutoResizeToChildrenHeight = bState

    self:InvalidateLayout()
end


---@param w number
---@param h number
---@private
function PANEL:_SizeChanged(w, h)

    self:CalcPaintOnce_Internal(w, h)

    if type(self.OnSizeChanged) == "function" then
        self:OnSizeChanged(w, h)
    end
end

---@private
---@param pnlChild Panel
function PANEL:OnChildAdded(pnlChild)
    self.bNeedUpdateSizeToChildren = true
end

---@private
---@param pnlChild Panel
function PANEL:OnChildRemoved(pnlChild)
    self.bNeedUpdateSizeToChildren = true
end

---@private
function PANEL:OnCursorEntered()
    self:CalcPaintOnce_Internal()

    if type(self.OnCursorJoin) == "function" then
        self:OnCursorJoin()
    end

end

---@private
function PANEL:OnCursorExited()
    self:CalcPaintOnce_Internal()

    if type(self.OnCursorExit) == "function" then
        self:OnCursorExit()
    end
end

function PANEL:PerformLayout(w, h)
    if self.bNeedUpdateSizeToChildren then
        local cw, ch = self:ChildrenSize()
        if self.bAutoResizeToChildrenWidth and self.bAutoResizeToChildrenHeight then
            self:SetSize(cw, ch)
        elseif self.bAutoResizeToChildrenWidth then
            self:SetWide(cw)
        elseif self.bAutoResizeToChildrenHeight then
            self:SetTall(ch)
        end

        self.bNeedUpdateSizeToChildren = false
    else
        if (self.LastPerformW != w) or (self.LastPerformH != h) then
            self.LastPerformW = w
            self.LastPerformH = h

            self:_SizeChanged(w, h)
        end
    end

end

vgui.Register("zpanelbase", PANEL, "EditablePanel")