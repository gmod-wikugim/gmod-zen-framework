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

    self.pnlBG = gui.CreateStyled("html_material", self)
    self.pnlBG:SetImage("zen/skin/rounded_rect.png")

    self.pnlClose_Size = 15
    self.pnlClose_RightMargin = 20
    self.pnlClose_TopMargin = 10
    self.pnlClose = gui.CreateStyled("html_material", self)
    self.pnlClose:SetImage("zen/skin/close.png")
    -- self.pnlClose:SetCursor("hand")
    -- self.pnlClose:SetSize(50, 50)

    self.pnlContent_TopMargin = 35
    self.pnlContent_BorderMargin = 2
    self.pnlContent = gui.Create("EditablePanel", self)
    self.pnlContent.Paint = function(self, w, h)
        draw.Line(0,0, w, 0, Color(43, 43, 43))
    end

    self.pnlTitle = gui.Create("DLabel", self)
    self.pnlTitle:SetContentAlignment(5)
    self.pnlTitle:SetFont("zen.gui.frame.Title")
    self.pnlTitle:SetText()
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
    -- print(w, h)
    if IsValid(self.pnlBG) then
        self.pnlBG:SetPos(0,0)
        self.pnlBG:SetSize(w,h)
    end

    if IsValid(self.pnlClose) then
        local margin = self.pnlClose_Margin
        local right_m = self.pnlClose_RightMargin
        local top_m = self.pnlClose_TopMargin
        local sz = self.pnlClose_Size
        self.pnlClose:SetSize(sz, sz)
        self.pnlClose:SetPos(w-sz-right_m, top_m)
    end

    if IsValid(self.pnlContent) then
        local top_m = self.pnlContent_TopMargin
        local border_m = self.pnlContent_BorderMargin
        self.pnlContent:SetSize(w-border_m*2, h-top_m-border_m)
        self.pnlContent:SetPos(border_m, top_m)
    end

    if IsValid(self.pnlTitle) then
        local top_m = self.pnlContent_TopMargin
        self.pnlTitle:SizeToContents(true, true)
        self.pnlTitle:CenterHorizontal()
        self.pnlTitle:InvalidateLayout(true)
        local tall = self.pnlTitle:GetTall()
        self.pnlTitle:SetY(top_m/2 - tall/2)
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
        center = "true"
    }
)