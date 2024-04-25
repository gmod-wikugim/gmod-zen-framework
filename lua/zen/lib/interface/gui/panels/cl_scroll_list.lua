module("zen", package.seeall)

local PANEL = {}

function PANEL:Init()
    local w, h = self:GetParent():GetWide()

    self.fScroll = 0


    self.wideVBar = 10
    self.pnlContent = gui.Create("EditablePanel", self)
    self.pnlContent.PaintOver = function(self, w, h)
        draw.BoxOutlined(3, 0, 0, w, h, COLOR.BLUE)


        local cw, ch = self:ChildrenSize()

        draw.BoxOutlined(1, 0, 0, cw, ch, COLOR.GREEN)
    end
    self.pnlContent.PerformLayout = function(_)
        local w, h = self:GetSize()
        self:PerformLayoutContent(w, h)

        self:InvalidateParent(true)
    end

    self.pnlContent:SetSize(w-self.wideVBar, h)
    -- self.pnlContent:SetSize()
    -- self.pnlContent:InvalidateLayout(true)

    local color_vbar = ColorAlpha(COLOR.WHITE, 20)
    local color_vbar_hovered = ColorAlpha(COLOR.WHITE, 255)
    self.pnlVBar = gui.Create("EditablePanel", self)
    self.pnlVBar.Paint = function(self, w, h)
        draw.BoxOutlined(1, 0, 0, w, h, COLOR.WHITE)
        if self:IsHovered() then
            draw.Box(0,0,w,h, color_vbar_hovered)
        else
            draw.Box(0,0,w,h, color_vbar)
        end
    end
    self.pnlVBar:SetCursor("hand")
    self.pnlVBar.OnMousePressed = function(_, code)
        if code == MOUSE_LEFT then
            self.moveStartX = self:GetX()
            self.moveStartY = self:GetY()
            local cx, cy = input.GetCursorPos()
            self.moveStartCursorX = cx
            self.moveStartCursorY = cy
            self.bMoveEnabled = true
        end
    end


    self.bPushNextChildrenToContent = true
    -- self:InvalidateParent(true)


    -- self:InvalidateLayout(true)
end

function PANEL:SetInBorder(vActive)
    self.bInBorder = vActive
    self:InvalidateLayout(true)
end

---comment
---@param fScroll number
function PANEL:SetScroll(fScroll)
    local base_w, base_h = self:GetSize()
    self.fScroll = fScroll

    if self.fScrollMax and self.fScroll > self.fScrollMax then
        self.fScroll = self.fScrollMax
    end

    if self.fScroll < 0 then
        self.fScroll = 0
    end

    self.pnlVBar:SetY(self.fScroll)
    self.pnlContent:SetY( - self.fScroll )
end

function PANEL:GetScroll()
    return self.fScroll
end

function PANEL:AddScroll(delta)
    self:SetScroll( self:GetScroll() - (delta * 5) )
end


function PANEL:OnMouseWheeled(delta)
    self:AddScroll(delta)
    return true
end

function PANEL:PerformLayout(w, h)
    local vbar_w = self.wideVBar
    if self.pnlContent then
        if self.bInBorder then
            self.pnlContent:SetWide(w)
        else
            self.pnlContent:SetWide(w-vbar_w)
        end

        if self.pnlContent:GetTall() < h then
            self.pnlContent:SetTall(h)
        end
    end
end

function PANEL:PerformLayoutContent(w, h)
    local vbar_w = self.wideVBar
    local content_w, content_h = self:GetContentSize(   )
    local child_w, child_h = self:GetContentChildrenSize()

    local percentage = math.min(1, h / math.max(child_h, h) )

    local vbar_h = percentage * h
    vbar_h = math.max(10, vbar_h)

    self.fScrollMultiply = percentage
    self.fScrollMax = h
    local vbar_y = self.fScroll

    self.pnlVBar:SetSize(vbar_w, vbar_h)
    self.pnlVBar:SetPos(w-vbar_w, vbar_y)

    self.pnlContent:SetTall(child_h)
end

function PANEL:GetContentSize()
    return self.pnlContent:GetSize()
end

function PANEL:GetContentChildrenSize()
    return self.pnlContent:ChildrenSize()
end

function PANEL:GetVBarSize()
    return self.pnlVBar:GetSize()
end


---@param pnlItem Panel
function PANEL:PushItem(pnlItem)
    -- self.pnlContent:InvalidateParent(true)
    pnlItem:SetParent(self.pnlContent)
    self.pnlContent:InvalidateParent(true)
    self.pnlContent:InvalidateLayout(true)


    local cc_w, cc_h = self:GetContentChildrenSize()

    self.pnlContent:SetTall(cc_h)
end


function PANEL:OnChildAdded(pnlItem)
    if self.bPushNextChildrenToContent then
        pnlItem:SetParent(self.pnlContent)
    end
end

function PANEL:Think()

    if self.bMoveEnabled then

        if not input.IsMouseDown(MOUSE_LEFT) then
            self.bMoveEnabled = false
            return
        end

        local screen_w, screen_h = ScrW(), ScrH()

        local panel_w, panel_h = self:GetSize()

        local start_x, start_y = self.moveStartX, self.moveStartY
        local start_cursor_x, start_cursor_y = self.moveStartCursorX, self.moveStartCursorY

        local now_cursor_x, now_cursor_y = input.GetCursorPos()

        local x_offset = now_cursor_x - start_cursor_x
        local y_offset = now_cursor_y - start_cursor_y

        local new_x = start_x + x_offset
        local new_y = start_y + y_offset

        new_x = math.Clamp(new_x, 0, screen_w - panel_w)
        new_y = math.Clamp(new_y, 0, screen_h - panel_h)


        self:SetPos(new_x, new_y)
    end
end

gui.RegisterStylePanel("scroll_list", PANEL, "EditablePanel")

local function CreatePanel()
    local pnlFrame = gui.CreateStyled("frame", nil, "menu_models",  {
        title = "Model Manager"
    })

    local pnlScroll = gui.CreateStyled("scroll_list", pnlFrame, nil, {"dock_fill"})
    -- pnlScroll:SetInBorder(true)

    -- pnlScroll:InvalidateLayout(true)
    local wide = pnlScroll:GetContentSize()

    local pnlLayout = gui.Create("DPanel", pnlScroll)
    pnlLayout:SetSize(wide, 120000   )
    pnlLayout.Paint = function(self, w, h)
        draw.Line(0,10, w, h-10)
        draw.Line(0,10, w, 10)
        draw.Line(0,h-10, w, h-10)
    end
    -- pnlLayout:SetImage("material/entities/edit_sky")

    -- local models = file.Find("models/*.mdl", "GAME")

    -- local wide = pnlScroll:GetContentSize()
    -- -- pnlScroll:InvalidateLayout(true)
    -- -- local wide = pnlScroll:GetWide()
    -- local items_per_row = 10


    -- local item_wide = wide/items_per_row

    -- if models then
    --     for k, mdl in pairs(models) do
    --         local pnlModel = gui.Create("DPanel", pnlLayout)
    --         pnlModel:SetSize(item_wide, 50)
    --         -- pnlModel:SetModel("models/" .. mdl)
    --     end
    -- end

end
-- CreatePanel()