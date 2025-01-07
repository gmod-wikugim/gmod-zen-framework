module("zen")

zen.FreePanelIDS = zen.FreePanelIDS or {}
zen.FreePanelIDS_Index = zen.FreePanelIDS_Index or {}

local FREE_IDS = zen.FreePanelIDS
local FREE_IDS_Index = zen.FreePanelIDS_Index

local table_remove = table.remove
local table_insert = table.insert
local string_format = string.format

---@return string
local function TakeID(width, height)
    FREE_IDS[width] = FREE_IDS[width] or {}
    FREE_IDS[width][height] = FREE_IDS[width][height] or {
        [0] = 0,
    }

    local INFO = FREE_IDS[width][height]


    local FreeID
    if INFO[1] != nil then
        FreeID = INFO[1]
        table_remove(INFO, 1)
    else
        INFO[0] = INFO[0] + 1 -- Counter
        FreeID = string_format("zen/PanelRT/%s/%s/%s", width, height, INFO[0])
    end

    FREE_IDS_Index[FreeID] = {width, height, INFO[0]}

    return FreeID
end

local function FreeID(DeleteID)
    local DATA = FREE_IDS_Index[DeleteID]
    if !DATA then return end

    local width = DATA[1]
    local height = DATA[2]

    FREE_IDS[width] = FREE_IDS[width] or {}
    FREE_IDS[width][height] = FREE_IDS[width][height] or {
        [0] = 0,
    }

    -- PrintTable(FREE_IDS)

    FREE_IDS_Index[DeleteID] = nil
    table_insert(FREE_IDS[width][height], DeleteID)
end

zen.iCounter_ZPanelBase = zen.iCounter_ZPanelBase or 0

---@class zen.panel.zpanelbase: Panel
---@field uniquePanelID string Unique ID for panel, memoryID or string with panel_num_id
---@field uniqueNumID number Unique Number ID for ZPanelBase panels
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
---@field PaintOnceBG fun(self, w:number, h:number) -- Works only with PaintOnce. Paint which called when panel: ChangeSize. (Un)Hovered. (De)Enable. (De)Blocked
---@field PaintOnceOver fun(self, w:number, h:number) -- Works only with PaintOnce. Paint which called when panel: ChangeSize. (Un)Hovered. (De)Enable. (De)Blocked
---@field PostRemove fun(self) -- Alias for OnRemove
local PANEL = {}

function PANEL:InternalInit()
    self.bPaintOnceEnabled = true
    self.LastPaintW = -1
    self.LastPaintH = -1

    self.LastPerformW = -1
    self.LastPerformH = -1

    self.bAutoDeleteTimerEnabled = false
    self.iAutoDeleteTimer = 10 -- Seconds

    ---@type table<number|string, fun(w:number, h:number)>
    self.tPaintOncePre = {}

    ---@type table<number|string, fun(w:number, h:number)>
    self.tPaintOncePost = {}

    ---@type table<number, Panel>
    self.tChildrenList = {}
    self.tChildrenList_Keys = {}

    ---@private
    self.bHoverPaintOnceEnabled = false

    ---@private
    self.bAutoResizeToChildrenWidth = false

    ---@private
    self.bAutoResizeToChildrenHeight = false

    ---@private
    self.bNeedUpdateSizeToChildren = false

    ---@private
    self.bAutoLayoutScheme = false

    self.bAutoLayoutIsVertical = true
    self.iAutoLayoutAmount = 1

    self.iAutoLayoutXStep = 5
    self.iAutoLayoutYStep = 5

    self.bAutoLayoutChangeChildSize = false


    self.bEnabled = true
    self.bDisabled = !self.bEnabled

    --- Show Panel is blocked. Is blocked, then input press/release also is blocked
    self.bBlocked = false

    self.tMousesPressed = {}
    self.tMousesPressTime = {}

    self.tSimpleTimers = {}
    self.tAdvTimers = {}

    ---@class zen.zpanel_base.render_target
    ---@field Target ITexture
    ---@field Func fun(w:number, h:number)

    ---@type table<string, zen.zpanel_base.render_target>
    self.tRenderTargets = {}
end


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

    self:InternalInit()

    zen.iCounter_ZPanelBase = zen.iCounter_ZPanelBase + 1
    self.uniqueNumID = zen.iCounter_ZPanelBase

    local bMemoryIDFounded, memoryID = pcall(string.format, "%p", self)

    if bMemoryIDFounded then
        self.uniquePanelID = memoryID
    else
        self.uniquePanelID = "zen.zpanel_base." .. tostring(self.uniqueNumID)
    end

    if self.bAutoDeleteTimerEnabled then
        self:AutoRemoveAfter(self.iAutoDeleteTimer)
    end
end


function PANEL:GetUniqueID() return self.uniquePanelID end

---Return UniquePanelID-some-some and etc.
---@vararg string
function PANEL:GetSubUniqueID(...) return string.format("%s-%s", self.uniquePanelID, table.concat({...}, "-")) end

---@param seconds number
---@param onFinish fun(self: zen.panel.zpanelbase)
function PANEL:SimpleTimer(seconds, onFinish)
    local timer_name = self:GetSubUniqueID("simple_timer", seconds)

    timer.Create(timer_name, seconds, 1, function()
        if !IsValid(self) then return end

        onFinish(self)
    end)

    self.tSimpleTimers[timer_name] = SysTime() + seconds
end

---Start timer with granted callback(Panel) exists, return not nil to stop timer
---@param uniqueID string
---@param seconds number
---@param reps number
---@param callback fun(self: zen.panel.zpanelbase): boolean?
function PANEL:Timer(uniqueID, seconds, reps, callback)
    local timer_name = self:GetSubUniqueID("adv_timer", uniqueID)

    timer.Create(timer_name, seconds, reps, function()
        if !IsValid(self) then
            timer.Remove(timer_name)
            return
        end

        local shouldStop = callback(self)

        if shouldStop != nil then
            timer.Remove(timer_name)
        end
    end)

    self.tAdvTimers[timer_name] = SysTime() + seconds * reps
end

function PANEL:StopTimer(uniqueID)
    local timer_name = self:GetSubUniqueID("adv_timer", uniqueID)
    timer.Remove(timer_name)
    self.tAdvTimers[timer_name] = nil
end

function PANEL:StopSimpleTimers()
    for timer_name in pairs(self.tSimpleTimers) do
        timer.Remove(timer_name)
        self.tSimpleTimers[timer_name] = nil
    end
end


function PANEL:StopTimers()
    for timer_name in pairs(self.tAdvTimers) do
        timer.Remove(timer_name)
        self.tAdvTimers[timer_name] = nil
    end
end

function PANEL:AutoRemoveAfter(seconds)
    self:Timer("auto-remove", seconds, 1, function()
        self:Remove()
    end)
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
    [LEFT] = true,
    [RIGHT] = true,
    [TOP] = true,
    [BOTTOM] = true
}

--- Smart dock with Invalidate Parent
---@param dock integer
---@param size number?
function PANEL:SDock(dock, size)

    self:Dock(dock)

    if type(size) == "number" then
        if t_isWideDock[dock] then
            self:SetWide(size)
        else
            self:SetTall(size)
        end
    end
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

--- Return panel global position
---@return number, number
function PANEL:GetGlobalPos()
    return vgui.GetWorldPanel():GetChildPosition(self)
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
    if !self.bPaintInitialized then
        self.bPaintInitialized = true

        self:CalcPaintOnce_Internal()
    end

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

    for _, v in pairs(self.tRenderTargets) do
        render.PushRenderTarget(v.Target)
            v.Func(w, h)
        render.PopRenderTarget()
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

    self:CalcPaintOnce_Internal()
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

    self:CalcPaintOnce_Internal()
end

--- Internal function for CreateMaterial
---@private
---@param w number
---@param h number
function PANEL:_PaintOnceFunction(w, h)
    for k, v in pairs(self.tPaintOncePre) do v(w, h) end

    if type(self.PaintOnceBG) == "function" then self:PaintOnceBG(w, h) end
    self:PaintOnce(w, h)
    if type(self.PaintOnceOver) == "function" then self:PaintOnceOver(w, h) end

    for k, v in pairs(self.tPaintOncePost) do v(w, h) end
end


---Add draw function to call before PaintOnce
---@param callback fun(w:number, h:number)
---@param uniqueID string?
function PANEL:AddPaintOncePreFunction(callback, uniqueID)
    if uniqueID then
        self.tPaintOncePre[uniqueID] = callback
    else
        table.insert(self.tPaintOncePre, callback)
    end
end

---Add draw function to call after PaintOnce
---@param callback fun(w:number, h:number)
---@param uniqueID string?
function PANEL:AddPaintOncePostFunction(callback, uniqueID)
    if uniqueID then
        self.tPaintOncePost[uniqueID] = callback
    else
        table.insert(self.tPaintOncePost, callback)
    end
end

---@param width number?
---@param height number?
function PANEL:CalcPaintOnce_Internal(width,  height)
    if !self.bPaintInitialized then return end
    if type(self.PaintOnce) != "function" then return end

    if (width == nil) then width = self:GetWide() end
    if (height == nil) then height = self:GetTall() end

    if self.iLastPaintOneWidth != width or self.iLastPaintOneHeiht != height then
        if self.renderTargetID != nil then
            FreeID(self.renderTargetID)
        end
        self.renderTargetID = TakeID(width, height)
    end

    if self.PaintMask then
        self.PaintOnceMaterial, PNG = material_cache.Generate2DMaterial(width, height, function(w, h)
            self:_PaintOnceFunction(width, height)
        end, function(w, h)
            self:PaintMask(w, h)
        end, false, self.renderTargetID)
    else
        self.PaintOnceMaterial, PNG = material_cache.Generate2DMaterial(width, height, function(w, h)
            self:_PaintOnceFunction(width, height)
        end, nil, false, self.renderTargetID)
    end

    self.iLastPaintOneWidth = width
    self.iLastPaintOneHeiht = height
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

--- Called when panel is removed
---@private
function PANEL:OnRemove()
    if type(self.PostRemove) == "function" then self:PostRemove() end

    do -- Stop timers
        for timer_name, iendtime in pairs(self.tAdvTimers) do
            if SysTime() <= iendtime then
                timer.Remove(timer_name)
            end
        end

        for timer_name, iendtime in pairs(self.tSimpleTimers) do
            if SysTime() <= iendtime then
                timer.Remove(timer_name)
            end
        end
    end

    do -- FreePanelIDS
        local TargetID = self.renderTargetID
        if TargetID then
            FreeID(self.renderTargetID)
        end
    end
end

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

    for RenderID, v in pairs(self.tRenderTargets) do
        v.Target = GetRenderTargetEx(RenderID,
            w, h,
            RT_SIZE_NO_CHANGE, -- Just no touch anything
            MATERIAL_RT_DEPTH_SHARED, -- Alpha use multiply alpha object. If any bags then change to --> MATERIAL_RT_DEPTH_SEPARATE --> MATERIAL_RT_DEPTH_ONLY
            1 + 256, -- Best Combo to enable high-equility screenshot
            0, -- Dont tested
            IMAGE_FORMAT_RGBA16161616 -- Allow use more colors in game. Default game colors is restricted!
        )
    end

    self:CalcPaintOnce_Internal(w, h)

    if type(self.OnSizeChanged) == "function" then
        self:OnSizeChanged(w, h)
    end
end

---@param bVertical boolean
---@param iItemAmount number? Defailt is [1]
---@param x_step number? x size between items
---@param y_step number? y size between items
---@param bChangeChildenSize boolean?
function PANEL:SetLayoutScheme(bVertical, iItemAmount, x_step, y_step, bChangeChildenSize)
    if bChangeChildenSize == nil then bChangeChildenSize = self.bAutoLayoutChangeChildSize end

    self.bAutoLayoutScheme = true
    self.bAutoLayoutIsVertical = bVertical
    self.iAutoLayoutAmount = iItemAmount or self.iAutoLayoutAmount
    self.iAutoLayoutXStep = x_step or self.iAutoLayoutXStep
    self.iAutoLayoutYStep = y_step or self.iAutoLayoutYStep
    self.bAutoLayoutChangeChildSize = bChangeChildenSize
end


local format = string.format
local tonumber = tonumber

function PANEL:SortChildrenZOrder()
    local childs = self:GetChildren()

    // TODO: Do sorting with zpos
end

function PANEL:RefreshAutoLayout()
    assert(self.bAutoLayoutScheme == true, "AutoLayoutScheme is not enabled!")

    -- print("Refresh", CurTime())

    local bVertical = self.bAutoLayoutIsVertical
    local iAmount = self.iAutoLayoutAmount

    local childs = self:GetChildren()

    self:SortChildrenZOrder()

    local StepX = self.iAutoLayoutXStep
    local StepY = self.iAutoLayoutYStep

    local CurrentX = StepX
    local CurrentY = StepY

    local bChangeSize = self.bAutoLayoutChangeChildSize



    local ItemSize = 0

    if bChangeSize then
        if bVertical then
            ItemSize = ( (self:GetWide() ) / iAmount) - (StepX)
        else
            ItemSize = ( (self:GetTall() ) / iAmount) - (StepY)
        end
    end


    local CurrentRowAmount = 0

    local ItemIndex = 0
    for k, pnl in pairs(childs) do
        pnl:SetPos(CurrentX, CurrentY)

        if bChangeSize then
            pnl:SetSize(ItemSize, ItemSize)
        end

        local pnlW, pnlH = pnl:GetSize()

        if iAmount > 1 then
            if bVertical then
                CurrentX = CurrentX + pnlW + StepX
            else
                CurrentY = CurrentY + pnlH + StepY
            end
        end

        CurrentRowAmount = CurrentRowAmount + 1
        ItemIndex = ItemIndex + 1

        if CurrentRowAmount >= iAmount then
            CurrentRowAmount = 0
            if bVertical then
                CurrentX = StepX
                CurrentY = CurrentY + pnlH + StepY
            else
                CurrentY = StepY
                CurrentX = CurrentX + pnlW + StepX
            end
        end
    end
end

---@private
---@param pnlChild Panel
function PANEL:OnChildAdded(pnlChild)
    self.bNeedUpdateSizeToChildren = true

    if self.tChildrenList_Keys[pnlChild] == nil then
        self.tChildrenList_Keys[pnlChild] = pnlChild
        table.insert(self.tChildrenList, pnlChild)
    end
end

function PANEL:GetChildren()
    return self.tChildrenList
end

---@private
---@param pnlChild Panel
function PANEL:OnChildRemoved(pnlChild)
    self.bNeedUpdateSizeToChildren = true

    if self.tChildrenList_Keys[pnlChild] != nil then
        self.tChildrenList_Keys[pnlChild] = nil

        for k, v in ipairs(self.tChildrenList) do
            if v != pnlChild then continue end

            table.remove(self.tChildrenList, k)
        end
    end
end

---@private
function PANEL:OnCursorEntered()
    self:CalcPaintOnce_Internal()

    if type(self.OnCursorJoin) == "function" then
        self:OnCursorJoin()
    end

end

---@param uniqueID string
---@param callback fun(w:number, h:number)
function PANEL:AddRenderFunction(uniqueID, callback)
    local RenderID = tostring(self.uniquePanelID) .. "_" .. tostring(uniqueID)


    local width, height = self:GetSize()

    local RenderTarget = GetRenderTargetEx(RenderID,
        width, height,
        RT_SIZE_NO_CHANGE, -- Just no touch anything
        MATERIAL_RT_DEPTH_SHARED, -- Alpha use multiply alpha object. If any bags then change to --> MATERIAL_RT_DEPTH_SEPARATE --> MATERIAL_RT_DEPTH_ONLY
        1 + 256, -- Best Combo to enable high-equility screenshot
        0, -- Dont tested
        IMAGE_FORMAT_RGBA16161616 -- Allow use more colors in game. Default game colors is restricted!
    )

    self.tRenderTargets[RenderID] = {
        Target = RenderTarget,
        Func = callback
    }
end

---@private
function PANEL:OnCursorExited()
    self:CalcPaintOnce_Internal()

    if type(self.OnCursorExit) == "function" then
        self:OnCursorExit()
    end
end

function PANEL:PerformLayout(w, h)
    if (self.LastPerformW != w) or (self.LastPerformH != h) then
        self.LastPerformW = w
        self.LastPerformH = h

        self:_SizeChanged(w, h)
    end

    do -- Childrens
        if self.bAutoResizeToChildrenWidth and self.bAutoResizeToChildrenHeight then
            local cw, ch = self:ChildrenSize()
            self:SetSize(cw, ch)
        elseif self.bAutoResizeToChildrenWidth then
            local cw, ch = self:ChildrenSize()
            self:SetWide(cw)
        elseif self.bAutoResizeToChildrenHeight then
            local cw, ch = self:ChildrenSize()
            self:SetTall(ch)
        end
    end

    if self.bAutoLayoutScheme == true then
        self:RefreshAutoLayout()
    end
end

vgui.Register("zpanelbase", PANEL, "EditablePanel")