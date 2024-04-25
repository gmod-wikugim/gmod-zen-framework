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

function PANEL:PaintOver(w,h)
    if self.iPercentageTake then
        draw.Text(self.iPercentageTake, 8, 10, 10, _COLOR.W)
    end
    if self.iPercentageScroll then
        draw.Text(self.iPercentageScroll, 8, 10, 20, _COLOR.W)
    end
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

    self.fScroll = math.min(self.fScroll, self.iCanvasFullTall - self.page_tall)

    self.pnlContent:SetY( - self.fScroll  )

    self.iPercentageScroll = self.fScroll / self.iCanvasFullTall + self.iPercentageTake

    self.pnlVBar:SetY( (self.iPercentageScroll - self.iPercentageTake) * base_h )
end

function PANEL:SetScrollPercantage(iPercentage)
    self.pnlContent:InvalidateLayout(true)

    local percentage_left = 1 - self.iPercentageTake
    self:SetScroll( ( (  iPercentage * percentage_left  )  *  self.iCanvasFullTall) )
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

        self.pnlContent:SetTall(self.iCanvasFullTall)
    end
end

function PANEL:PerformLayoutContent(w, h)
    local vbar_w = self.wideVBar
    local content_w, content_h = self:GetContentSize(   )
    local child_w, child_h = self:GetContentChildrenSize()

    self.iCanvasFullTall = math.max(h, child_h)

    self.iPercentageTake =  h / self.iCanvasFullTall
    if !self.iPercentageScroll then
        self.iPercentageScroll = self.iPercentageTake
    end

    self.page_tall = h

    self.vbar_tall = self.iPercentageTake * h

    self.pnlVBar:SetSize(vbar_w, self.vbar_tall)
    self.pnlVBar:SetX(w-vbar_w)
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

function PANEL:OnChildAdded(pnlItem)
    if self.bPushNextChildrenToContent then
        pnlItem:SetParent(self.pnlContent)
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
    pnlLayout:SetSize(wide, 1000)
    pnlLayout:Dock(TOP)
    pnlLayout.Paint = function(self, w, h)
        draw.Line(0,10, w, h-10)
        draw.Line(w,10, 0, h-10)
        draw.Line(0,10, w, 10)
        draw.Line(0,h-10, w, h-10)
    end

    -- timer.Simple(0.1, function()

    for k = 1, 10 do
        vgui.Create("DPanel", pnlScroll):Dock(TOP)
    end

    pnlScroll:SetScrollPercantage(1)

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
CreatePanel()