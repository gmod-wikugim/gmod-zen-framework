module("zen", package.seeall)

local s_SetDrawColor = surface.SetDrawColor
local s_DrawRect = surface.DrawRect
local s_DrawText = surface.DrawText
local s_SetTextPos = surface.SetTextPos
local s_SetFont = surface.SetFont
local s_GetTextSize = surface.GetTextSize
local s_SetTextColor = surface.SetTextColor
local s_SetMaterial = surface.SetMaterial
local s_DrawTexturedRect = surface.DrawTexturedRect
local s_DrawTexturedRectRotated = surface.DrawTexturedRectRotated
local s_DrawLine = surface.DrawLine
local s_DrawPoly = surface.DrawPoly
local s_DrawOutlinedRect = surface.DrawOutlinedRect

local rad = math.rad
local sin = math.sin
local cos = math.cos
local math_ceil = math.ceil
local tostring = tostring


surface.CreateFont("zen.gui.frame.Title", {
    font = "Segoe UI",
    size = 25,
    weight = 300,
})

local PANEL = {}

function PANEL:Init()
    -- self.pnlClose = gui.CreateStyled("button", self)
    self.tallHeader = 30
    self.mainBorder = 2

    self.pnlBG = gui.CreateStyled("html_material", self)
    self.pnlBG:SetImage("zen/skin/rounded_rect.png")

    self.pnlHeader = gui.Create("EditablePanel", self)
    self.pnlHeader:SetCursor("hand")
    self.pnlHeader.OnMousePressed = function(_, code)
        if code == MOUSE_LEFT then
            self.moveStartX = self:GetX()
            self.moveStartY = self:GetY()
            local cx, cy = input.GetCursorPos()
            self.moveStartCursorX = cx
            self.moveStartCursorY = cy
            self.bMoveEnabled = true
        end
    end

    local hover_color = ColorAlpha(COLOR.R, 100)
    self.pnlClose = gui.CreateStyled("html_button", self)
    self.pnlClose:SetImage("zen/skin/close.png")
    self.pnlClose:SetCursor("hand")
    self.pnlClose:SetImageSize(15, 15)
    self.pnlClose.Paint = function(self, w, h)
        if self:IsHovered()  then
            draw.Box(0,0,w,h, hover_color)
        end
    end
    self.pnlClose_Wide = 50
    self.pnlClose.DoClick = function()
        self:Remove()
    end
    self.pnlClose:SetFocusTopLevel(true)
    self.pnlClose:SetZPos(32767)

    self.pnlContent = gui.Create("EditablePanel", self)
    self.pnlContent.Paint = function(self, w, h)
        draw.Line(0,0, w, 0, Color(43, 43, 43))
    end

    self.pnlTitle = gui.Create("DLabel", self.pnlHeader)
    self.pnlTitle:SetContentAlignment(5)
    self.pnlTitle:SetFont("zen.gui.frame.Title")
    self.pnlTitle:SetText("")
end

---@param text string
function PANEL:SetTitle(text)
    self.pnlTitle:SetText(text)
    self:InvalidateLayout(true)
end

function PANEL:DoClick()
    -- Base DoClick stuff
end

function PANEL:PerformLayout(w, h)
    local tall_header = self.tallHeader
    local main_border = self.mainBorder
    -- print(w, h)
    if IsValid(self.pnlBG) then
        self.pnlBG:SetPos(0,0)
        self.pnlBG:SetSize(w,h)
    end

    if IsValid(self.pnlHeader) then
        self.pnlHeader:SetPos(0,0)
        self.pnlHeader:SetSize(w, self.tallHeader)
    end

    if IsValid(self.pnlClose) then
        local wide = self.pnlClose_Wide
        self.pnlClose:SetSize(wide, tall_header-main_border)
        self.pnlClose:SetPos(w-wide-main_border, main_border)
    end

    if IsValid(self.pnlContent) then
        self.pnlContent:SetSize(w-main_border*2, h-tall_header-main_border)
        self.pnlContent:SetPos(main_border, tall_header)
    end

    if IsValid(self.pnlTitle) then
        self.pnlTitle:SizeToContents(true, true)
        self.pnlTitle:Center()
        -- self.pnlTitle:InvalidateLayout(true)
        -- local tall = self.pnlTitle:GetTall()
        -- self.pnlTitle:SetY(self/2 - tall/2)
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


function PANEL:Paint(w, h)
end

function PANEL:OnMousePressed(code)
    if code == MOUSE_LEFT then
        if self.DoClick then
            self:DoClick()
        end
    end
end

gui.RegisterStylePanel("frame",
    PANEL,
    "EditablePanel",
    {
        min_size = {800, 600},
        mouse_input = true,
        center = "true",
        popup = true,
    }
)