local ui, gui, draw = zen.Import("ui", "gui", "ui.draw")


local color_nofocus = Color(150,150,150,200)
local color_bg = Color(80,80,80,255)

gui.RegisterStylePanel("help_text_array", {
    Init = function(self)
        self.tsArray = false
        self.iTextX = 5
        self.iTextY = 5
        self:NoClipping(true)
    end,
    UpdatePostion = function(self)
        local x, y, w, h = self:CalcPosSize()
        self:SetSize(w, h)
        self:SetPos(x, y)
    end,
    SetPanel = function(self, pnl)
        self.pnlTarget = pnl
    end,
    CalcPosSize = function(self)
        if not self.tsArray then return end
        local tw, th = draw.TextArray_Size(self.tsArray)
        tw = tw + self.iTextX * 2
        th = th + self.iTextY * 2

        local nw, nh = tw, th
        local ow, oh = self.pnlTarget:GetSize()
        local ox, oy = vgui.GetWorldPanel():GetChildPosition(self.pnlTarget)
        local scrw, scrh = ScrW(), ScrH()

        local inScreen = function(nx, ny)
            local end_wide = nx + nw
            local end_tall = ny + nh

            if end_wide < 0 or end_tall < 0 then return false end
            if end_wide > scrw or end_tall > scrh then return false end

            if nx < 0 or ny < 0 then return false end
            if nx > scrw or ny > scrw then return false end

            return true
        end

        do -- Right
            local nx, ny = ox + ow, oy
            if inScreen(nx, ny) then return nx, ny, nw, nh end
        end

        do -- Left
            local nx, ny = ox-nw, oy
            if inScreen(nx, ny) then return nx, ny, nw, nh end
        end

        do -- Up
            local nx, ny = ox, oy-oh
            if inScreen(nx, ny) then return nx, ny, nw, nh end
        end

        do -- Down
            local nx, ny = ox, oy+oh
            if inScreen(nx, ny) then return nx, ny, nw, nh end
        end

        return ox, oy, nw, nh
    end,
    SetHelp = function(self, tsArray)
        self.tsArray = tsArray
        self:UpdatePostion()
    end,
    Paint = function(self, w, h)
        if not self.bActive or not self.tsArray then return end
        draw.Box(0,0,w,h,color_bg)
        draw.BoxOutlined(1,0,0,w,h,color_nofocus)
        draw.TextArray(self.iTextX, self.iTextY, self.tsArray)
    end,
    Think = function(self)
        if not IsValid(self.pnlTarget) then self:Remove() return end

        if not self.tsArray then return end

        local cx, cy = self.pnlTarget:LocalCursorPos()
        local ow, oh = self.pnlTarget:GetSize()

        local ox, oy = vgui.GetWorldPanel():GetChildPosition(self.pnlTarget)
        if ox != self.lastOX or oy != self.lastOY then
            self.lastOX = ox
            self.lastOY = oy
            self:UpdatePostion()
        end

        if cx > 0 and cy > 0 and cx < ow and cy < oh then
            self.bActive = true
        else
            self.bActive = false
        end
    end
}, "EditablePanel", {key_input = false, mouse_input = false, draw_on_top = true}, {})

function META.PANEL:zen_SetHelpTextArray(tsArray)
    if tsArray == nil then
        if IsValid(self.pnlHelp) then
            self.pnlHelp:Remove()
        end

        return
    end

    if not IsValid(self.pnlHelp) then
        self.pnlHelp = gui.CreateStyled("help_text_array")
        self.pnlHelp:SetPanel(self)
    end

    self.pnlHelp:SetHelp(tsArray)
end